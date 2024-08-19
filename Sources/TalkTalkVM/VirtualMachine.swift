//
//  VirtualMachine.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Foundation
import TalkTalkBytecode

public enum Verbosity: Equatable {
	case quiet, verbose
	case lineByLine(String)
}

public struct VirtualMachine {
	// The module to run. Must be compiled in executable mode.
	var module: Module

	// Should we print disassembled instructions/stack dumps on each tick
	var verbosity: Verbosity

	var ip: UInt64 {
		get {
			currentFrame.ip
		}

		set {
			currentFrame.ip = newValue
		}
	}

	// The code to run
	var chunk: Chunk {
		currentFrame.chunk
	}

	// The frames stack
	var frames: Stack<CallFrame> {
		willSet {
			if frames.size != newValue.size, frames.size > 0, verbosity != .quiet {
				log("       <- \(frames.peek().chunk.name), depth: \(frames.peek().chunk.depth) locals: \(frames.peek().chunk.localNames)")
			}
		}

		didSet {
			if frames.size != oldValue.size, frames.size > 0, verbosity != .quiet {
				log("       -> \(frames.peek().chunk.name), depth: \(frames.peek().chunk.depth) locals: \(frames.peek().chunk.localNames)")
			}
		}
	}

	// The current call frame
	var currentFrame: CallFrame {
		get {
			frames.peek()
		}

		set {
			frames[frames.size - 1] = newValue
		}
	}

	// The stack
	var stack: Stack<Value>

	// A fake heap
	var heap = Heap()

	public static func run(module: Module, verbosity: Verbosity = .quiet) throws -> ExecutionResult {
		var vm = VirtualMachine(module: module, verbosity: verbosity)
		return try vm.run()
	}

	public init(module: Module, verbosity: Verbosity = .quiet) {
		self.module = module
		self.verbosity = verbosity

		guard let chunk = module.main else {
			fatalError("no entrypoint found for module `\(module.name)`")
		}

		self.stack = Stack<Value>(capacity: 256)
		self.frames = Stack<CallFrame>(capacity: 256)

		// Reserving this space
		stack.push(.reserved)

		frames.push(
			CallFrame.allocate(for: chunk, returnTo: 0, heap: heap, arguments: [])
		)
	}

	public mutating func run() throws -> ExecutionResult {
		while true {
			#if DEBUG
				func dumpInstruction() -> Instruction? {
					var disassembler = Disassembler(chunk: chunk)
					disassembler.current = Int(ip)
					if let instruction = disassembler.next() {
						dumpStack()
						instruction.dump()
						return instruction
					}
					return nil
				}

				switch verbosity {
				case .quiet:
					()
				case .verbose:
					_ = dumpInstruction()
				case let .lineByLine(string):
					if let i = dumpInstruction() {
						if i.line < string.components(separatedBy: .newlines).count {
							let line = string.components(separatedBy: .newlines)[Int(i.line)]
							log("       " + line)
						} else {
							log("       <lib>\n")
						}
					}
				}
			#endif

			let byte = readByte()

			guard let opcode = Opcode(rawValue: byte) else {
				fatalError("Unknown opcode: \(byte)")
			}

			switch opcode {
			case .return:
				// Remove the result from the stack temporarily while we clean it up
				let result = stack.pop()
				let calledFrame = frames.pop()

				// If there are no frames left, we're done.
				if frames.size == 0 {
					// Make sure we didn't leak anything, we should only have the main program
					// on the stack.
					if verbosity == .verbose {
						if stack.size != 0 {
							print("stack size expected to be 0, got: \(stack.size)")
							dumpStack()
						}
					}

					return .ok(result)
				}

				// Push the result back onto the stack
				stack.push(result)

				// Return to where we called from
				ip = calledFrame.returnTo
			case .suspend:
				return .ok(stack.peek())
			case .constant:
				let value = readConstant()
				stack.push(value)
			case .true:
				stack.push(.bool(true))
			case .false:
				stack.push(.bool(false))
			case .none:
				stack.push(.none)
			case .primitive:
				stack.push(.primitive(Primitive(rawValue: readByte())!))
			case .negate:
				let value = stack.pop()
				if let intValue = value.intValue {
					stack.push(.int(-intValue))
				} else {
					return runtimeError("Cannot negate \(value)")
				}
			case .not:
				let value = stack.pop()
				if let bool = value.boolValue {
					stack.push(.bool(!bool))
				}
			case .equal:
				let lhs = stack.pop()
				let rhs = stack.pop()
				stack.push(.bool(lhs == rhs))
			case .notEqual:
				let lhs = stack.pop()
				let rhs = stack.pop()
				stack.push(.bool(lhs != rhs))
			case .add:
				let lhsValue = stack.pop()
				let rhsValue = stack.pop()

				switch (lhsValue, rhsValue) {
				case let (.int(lhs), .int(rhs)):
					stack.push(.int(lhs + rhs))
				case let (.string(lhs), .string(rhs)):
					stack.push(.string(lhs + rhs))
				case let (.pointer(pointer), .int(rhs)):
					stack.push(.pointer(pointer + rhs))
				case let (.data(lhs), .data(rhs)):
					let lhs = chunk.data[Int(lhs)]
					let rhs = chunk.data[Int(rhs)]

					guard lhs.kind == .string, lhs.kind == .string else {
						return runtimeError("Cannot add two data operands: \(lhs), \(rhs)")
					}

					let bytes = lhs.bytes + rhs.bytes
					let pointer = heap.allocate(count: bytes.count)

					for i in 0 ..< bytes.count {
						heap.store(pointer: pointer, value: .byte(bytes[i]))
					}

					stack.push(.pointer(pointer))
				default:
					return runtimeError("Cannot add \(lhsValue) to \(rhsValue) operands")
				}
			case .subtract:
				guard let lhs = stack.pop().intValue,
				      let rhs = stack.pop().intValue
				else {
					return runtimeError("Cannot subtract none int operands")
				}
				stack.push(.int(lhs - rhs))
			case .divide:
				guard let lhs = stack.pop().intValue,
				      let rhs = stack.pop().intValue
				else {
					return runtimeError("Cannot divide none int operands")
				}
				stack.push(.int(lhs / rhs))
			case .multiply:
				guard let lhs = stack.pop().intValue,
				      let rhs = stack.pop().intValue
				else {
					return runtimeError("Cannot multiply none int operands")
				}
				stack.push(.int(lhs * rhs))
			case .less:
				guard let lhs = stack.pop().intValue,
				      let rhs = stack.pop().intValue
				else {
					return runtimeError("Cannot compare none int operands")
				}
				stack.push(.bool(lhs < rhs))
			case .greater:
				guard let lhs = stack.pop().intValue,
				      let rhs = stack.pop().intValue
				else {
					return runtimeError("Cannot compare none int operands")
				}
				stack.push(.bool(lhs > rhs))
			case .lessEqual:
				guard let lhs = stack.pop().intValue,
				      let rhs = stack.pop().intValue
				else {
					return runtimeError("Cannot compare none int operands")
				}
				stack.push(.bool(lhs <= rhs))
			case .greaterEqual:
				guard let lhs = stack.pop().intValue,
				      let rhs = stack.pop().intValue
				else {
					return runtimeError("Cannot compare none int operands")
				}
				stack.push(.bool(lhs >= rhs))
			case .data:
				let slot = readByte()
				let data = chunk.data[Int(slot)]
				switch data.kind {
				case .string:
					stack.push(.string(String(data: Data(data.bytes), encoding: .utf8) ?? "<invalid string>"))
				}
			case .pop:
				stack.pop()
			case .loop:
				ip -= readUInt16()
			case .jump:
				ip += readUInt16()
			case .jumpUnless:
				let jump = readUInt16()
				if stack.peek() == .bool(false) {
					ip += jump
				}
			case .getLocal:
				switch readPointer() {
				case let .stack(slot):
					if let value = currentFrame.locals[Int(slot)] {
						stack.push(value)
					} else {
						return runtimeError("Could not find local at slot \(slot) in frame: \(currentFrame.locals)")
					}
				case let .heap(slot):
					if let value = heap.dereference(block: Int(slot), offset: Int(slot)) {
						stack.push(value)
					} else {
						return runtimeError("Could not find local at slot \(slot) in frame: \(currentFrame.locals)")
					}
				case .moduleValue(_):
					()
				case .moduleFunction(_):
					()
				case .moduleStruct(_):
					()
				case .builtinFunction(_):
					()
				case .null:
					()
				}
			case .setLocal:
				let pointer = readPointer()
				try store(stack.peek(), in: pointer)

				if case var .instance(instance) = stack.peek() {
					instance.pointer = pointer
					stack[stack.size-1] = .instance(instance)
				}
			case .defClosure:
				// Read which subchunk this closure points to
				let slot = readByte()

				// Read the local slot if this is a named function
				let localSlot = readPointer()
				switch localSlot {
				case .stack(let byte):
					currentFrame.locals[Int(byte)] = .closure(.init(slot))
				case .heap(let byte):
					currentFrame.heap[Int(byte)] = .closure(.init(slot))
				case .null:
					() // it's not named
				default:
					return runtimeError("bad pointer: \(localSlot)")
				}

				

				stack.push(.closure(.init(slot)))
			case .call:
				let callee = stack.pop()
				if callee.isCallable {
					call(callee)
				} else {
					return runtimeError("\(callee) is not callable")
				}
			case .callChunkID:
				let slot = readByte()
				let chunk = chunk.getChunk(at: Int(slot))
				call(chunk: chunk)
			case .getModuleFunction:
				let slot = readByte()
				if let global = module.functions[slot] {
					stack.push(global)
				} else {
					return runtimeError("No module function at slot: \(slot)")
				}
			case .setModuleFunction:
				return runtimeError("cannot set module functions")
			case .getModuleValue:
				guard case let .moduleValue(slot) = readPointer() else {
					return runtimeError("bad pointer for module value")
				}

				if let global = module.values[slot] {
					stack.push(global)
				} else if let initializer = module.valueInitializers[slot] {
					// If we don't have the global already, we lazily initialize it by running its initializer
					call(chunk: initializer)

					module.values[slot] = stack.peek()

					// Remove the initializer since it should only be called once
					module.valueInitializers.removeValue(forKey: slot)
				} else {
					return runtimeError("No global found at slot: \(slot)")
				}
			case .setModuleValue:
				guard case let .moduleValue(slot) = readPointer() else {
					return runtimeError("bad pointer for module value")
				}

				module.values[slot] = stack.peek()

				// Remove the lazy initializer for this value since we've already initialized it
				module.valueInitializers.removeValue(forKey: slot)
			case .getBuiltin:
				guard case let .builtinFunction(slot) = readPointer() else {
					return runtimeError("incorrect builtin function")
				}

				stack.push(.builtin(slot))
			case .setBuiltin:
				return runtimeError("Cannot set built in")
			case .getStruct:
				guard case let .moduleStruct(slot) = readPointer() else {
					return runtimeError("no struct for pointer")
				}

				let structType = module.structs[Int(slot)]
				stack.push(.struct(structType))
			case .setStruct:
				return runtimeError("Cannot set struct")
			case .getProperty:
				// Get the slot of the member
				let slot = readByte()

				// PropertyOptions let us see if this member is a method
				let propertyOptions = PropertyOptions(rawValue: readByte())

				// Pop the receiver off the stack
				let receiver = stack.pop()
				switch receiver {
				case let .instance(receiver):
					if propertyOptions.contains(.isMethod) {
						// If it's a method, we create a boundMethod value, which consists of the method slot
						// and the instance ID. Using this, we can use the type we get from instance[instanceID]
						// to lookup the method.
						let boundMethod = Value.boundMethod(receiver, .init(slot))

						stack.push(boundMethod)
					} else {
						guard let value = receiver.fields[Int(slot)] else {
							fatalError("No value in slot: \(slot)")
						}

						stack.push(value)
					}
				default:
					return runtimeError("Receiver is not an instance of a struct")
				}
			case .is:
				let lhs = stack.pop()
				let rhs = stack.pop()

				checkType(instance: lhs, type: rhs)
			case .setProperty:
				let slot = readByte()
				let instance = stack.pop()
				let propertyValue = stack.peek()

				guard var (receiver) = instance.instanceValue else {
					return runtimeError("Receiver is not a struct: \(instance)")
				}

				receiver.fields[Int(slot)] = propertyValue

				if let pointer = receiver.pointer {
					try store(.instance(receiver), in: pointer)
				}
			case .jumpPlaceholder:
				()
			case .alloca:
				()
			case .malloca:
				()
			}
		}
	}

	func load(pointer: Pointer) throws -> Value {
		switch pointer {
		case let .stack(slot):
			return currentFrame.locals[Int(slot)]!
		case let .heap(slot):
			return currentFrame.heap[Int(slot)]!
		default:
			throw ExecutionResult.Error.error("invalid store destination: \(pointer)")
		}
	}

	mutating func store(_ value: Value, in pointer: Pointer) throws {
		switch pointer {
		case let .stack(slot):
			currentFrame.locals[Int(slot)] = value
		case let .heap(slot):
			heap[Int(slot)] = value
		default:
			throw ExecutionResult.Error.error("invalid store destination: \(pointer)")
		}
	}

	mutating func checkType(instance: Value, type: Value) {
		stack.push(.bool(instance.is(type)))
	}

	mutating func call(_ callee: Value) {
		switch callee {
		case let .builtin(builtin):
			call(builtin: Int(builtin))
		case let .moduleFunction(moduleFunction):
			call(moduleFunction: Int(moduleFunction))
		case let .struct(structValue):
			call(structType: structValue)
		case let .boundMethod(instance, methodSlot):
			call(boundMethod: methodSlot, on: instance)
		case let .closure(closure):
			call(chunk: chunk.getChunk(at: Int(closure)))
		default:
			fatalError("\(callee) is not callable")
		}
	}

	// Call a method on an instance.
	// Takes the method offset, instance and type that defines the method.
	mutating func call(boundMethod: Value.IntValue, on instance: Instance) {
		let methodChunk = instance.type.methods[Int(boundMethod)]

		var frame = CallFrame.allocate(for: methodChunk, returnTo: ip, heap: heap.allocate(count: Int(methodChunk.heapValueCount)), arguments: stack.pop(count: Int(methodChunk.arity)))

		frame.locals[0] = .instance(instance)
		frames.push(frame)
	}

	mutating func call(structType: Struct) {
		let instance = Instance(type: structType, fields: Array(repeating: nil, count: structType.propertyCount))

		// Get the initializer
		let chunk = structType.methods[structType.initializer]

		var frame = CallFrame.allocate(
			for: chunk,
			returnTo: ip,
			heap: heap.allocate(count: Int(chunk.heapValueCount)),
			arguments: stack.pop(count: Int(chunk.arity))
		)

		// The 0 index slot in locals is reserved for `self`
		frame.locals[0] = .instance(instance)
		frames.push(frame)
	}

	mutating func call(chunk: Chunk) {
		let frame = CallFrame.allocate(
			for: chunk,
			returnTo: ip,
			heap: heap.allocate(count: Int(chunk.heapValueCount)),
			arguments: stack.pop(count: Int(chunk.arity))
		)

		frames.push(frame)
	}

	mutating func call(moduleFunction: Int) {
		let chunk = module.chunks[moduleFunction]
		call(chunk: chunk)
	}

	func inspect(_ value: Value) -> String {
		switch value {
		case let .string(string):
			string
		default:
			value.description
		}
	}

	mutating func call(builtin: Int) {
		guard let builtin = BuiltinFunction(rawValue: Byte(builtin)) else {
			fatalError("no builtin at index: \(builtin)")
		}

		switch builtin {
		case .print:
			let value = stack.peek()
			print(inspect(value))
		case ._allocate:
			if case let .int(count) = stack.pop() { // Get the capacity
				let block = heap.allocate(count: Int(count))
				stack.push(.pointer(.init(block.address), .init(0)))
			}
		case ._deref:
			if case let .pointer(blockID, offset) = stack.pop(),
			   let value = heap.dereference(block: Int(blockID), offset: Int(offset))
			{
				stack.push(value)
			}
		case ._free:
			() // TODO:
		case ._storePtr:
			let value = stack.pop()
			if case let .pointer(blockID, offset) = stack.pop() {
				heap.store(block: Int(blockID), offset: Int(offset), value: value)
			}
		}
	}

	mutating func readConstant() -> Value {
		let value = chunk.constants[Int(readByte())]
		return value
	}

	mutating func readByte() -> Byte {
		chunk.code[Int(ip++)]
	}

	mutating func readPointer() -> Pointer {
		let a = readByte()
		let b = readByte()
		return Pointer(bytes: (a, b))
	}

	mutating func readUInt16() -> UInt64 {
		var jump = UInt64(readByte() << 8)
		jump |= UInt64(readByte())
		return jump
	}

//	mutating func captureUpvalue(value: Value) -> Upvalue {
//		var previousUpvalue: Upvalue? = nil
//		var upvalue = openUpvalues
//
//		while upvalue != nil /* , upvalue!.value > value */ {
//			previousUpvalue = upvalue
//			upvalue = upvalue!.next
//		}
//
//		if let upvalue, upvalue.value == value {
//			return upvalue
//		}
//
//		let createdUpvalue = Upvalue(value: value)
//		createdUpvalue.next = upvalue
//
//		if let previousUpvalue {
//			previousUpvalue.next = createdUpvalue
//		} else {
//			openUpvalues = createdUpvalue
//		}
//
//		return createdUpvalue
//	}

	func runtimeError(_ message: String) -> ExecutionResult {
		.error(message)
	}

	@discardableResult mutating func dumpStack() -> String {
		if stack.isEmpty { return "" }
		var result = "       Stack: "
		for slot in stack.entries() {
			if frames.size == 0 {
				result += "[ \(slot.description) ]"
			} else {
				result += "[ \(slot.disassemble(in: chunk)) ]"
			}
		}

		if frames.size > 0 {
			result += "\n       Locals: "
			for slot in currentFrame.locals {
				result += "[ \(slot?.disassemble(in: chunk) ?? "<uninitialized>") ]"
			}
		}

		result += "\n       Frame count: \(frames.size)"

		log(result)

		return result
	}

	mutating func log(_ string: String) {
		FileHandle.standardError.write(Data((string + "\n").utf8))
	}

	mutating func dump() {
		var disassembler = Disassembler(chunk: chunk)
		for instruction in disassembler.disassemble() {
			let prefix = instruction.offset == ip ? "> " : "  "
			print(prefix + instruction.description)

			if instruction.offset == ip {
				dumpStack()
			}
		}
	}
}
