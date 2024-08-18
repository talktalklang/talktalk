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
		currentFrame.closure.chunk
	}

	// The frames stack
	var frames: Stack<CallFrame> {
		willSet {
			if frames.size != newValue.size, frames.size > 0, verbosity != .quiet {
				log("       <- \(frames.peek().closure.chunk.name)()")
			}
		}

		didSet {
			if frames.size != oldValue.size, frames.size > 0, verbosity != .quiet {
				log("       -> \(frames.peek().closure.chunk.name)()")
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

	// Closure storage
	var closures: [UInt64: Closure] = [:]

	// Upvalue linked list
	var openUpvalues: Upvalue?
	public static func run(module: Module, verbosity: Verbosity = .quiet) -> ExecutionResult {
		var vm = VirtualMachine(module: module, verbosity: verbosity)
		return vm.run()
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

		let frame = CallFrame(
			closure: Closure(chunk: chunk, upvalues: []),
			returnTo: 0,
			stackOffset: 0,
			locals: .init(repeating: nil, count: Int(chunk.localsCount)),
			instances: [],
			builtinInstances: []
		)

		frames.push(frame)
	}

	public mutating func run() -> ExecutionResult {
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

				// TODO: Close upvalues

				let calledFrame = frames.pop()

				// Pop off values created on the stack by the called frame
				while stack.size > calledFrame.stackOffset + 1 {
					stack.pop()
				}

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

				// Update frame instances to reflect changes that happened in last frame
				for i in 0 ..< currentFrame.instances.count {
					currentFrame.instances[i] = calledFrame.instances[i]
				}

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
				case let (.pointer(base, offset), .int(rhs)):
					stack.push(.pointer(base, offset + rhs))
				case let (.data(lhs), .data(rhs)):
					let lhs = chunk.data[Int(lhs)]
					let rhs = chunk.data[Int(rhs)]

					guard lhs.kind == .string, lhs.kind == .string else {
						return runtimeError("Cannot add two data operands: \(lhs), \(rhs)")
					}

					let bytes = lhs.bytes + rhs.bytes
					let addr = heap.allocate(count: bytes.count)

					for i in 0 ..< bytes.count {
						heap.store(block: addr, offset: i, value: .byte(bytes[i]))
					}

					stack.push(.pointer(.init(addr), 0))
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
				let slot = readByte()

				if let value = currentFrame.locals[Int(slot)] {
					stack.push(value)
				} else {
					return runtimeError("Could not find local at slot \(slot) in frame: \(currentFrame.locals)")
				}
//				stack.push(stack[Int(slot) + currentFrame.stackOffset])
			case .setLocal:
				let slot = readByte()
				currentFrame.locals[Int(slot)] = stack.peek()
//				stack[Int(slot) + currentFrame.stackOffset] = stack.peek()
			case .getUpvalue:
				let slot = readByte()
				let upvalue = currentFrame.closure.upvalues[Int(slot)]
				guard let value = frames[frames.size - 1 - Int(upvalue.depth)].locals[Int(upvalue.slot)] else {
					return runtimeError("Could not find upvalue: \(upvalue)")
				}

				stack.push(value)
			case .setUpvalue:
				let slot = readByte()
				let upvalue = currentFrame.closure.upvalues[Int(slot)]
				frames[frames.size - 1 - Int(upvalue.depth)].locals[Int(upvalue.slot)] = stack.peek()
			case .defClosure:
				// Read which subchunk this closure points to
				let slot = readByte()

				// Read the local slot if this is a named function
				let localSlot = readByte()

				// Load the subchunk TODO: We could probably just store the index in the closure?
				let subchunk = chunk.getChunk(at: Int(slot))

				// Capture upvalues
				var upvalues: [Upvalue] = []
				for _ in 0 ..< subchunk.upvalueCount {
					let depth = readByte()
					let slot = readByte()
					upvalues.append(Upvalue(depth: depth, slot: slot))

//					if isLocal {
//						// If the upvalue is local, that means it is defined in the current call frame. That
//						// means we want to capture the value.
//						let value = stack[Int(index)]
//						let upvalue = captureUpvalue(value: value)
//						upvalues.append(upvalue)
//					} else {
//						// If it's not local, that means it's already been captured and the current call frame's
//						// knowledge of the value is an upvalue as well.
//						upvalues.append(currentFrame.closure.upvalues[Int(index)])
//					}
				}

				// Store the closure TODO: gc these when they're not needed anymore
				closures[UInt64(slot)] = Closure(chunk: subchunk, upvalues: upvalues)

				if localSlot != 0 {
					currentFrame.locals[Int(localSlot)] = .closure(.init(slot))
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
				call(chunkID: Int(slot))
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
				let slot = readByte()
				if let global = module.values[slot] {
					stack.push(global)
				} else if let initializer = module.valueInitializers[slot] {
					// If we don't have the global already, we lazily initialize it by running its initializer
					call(inline: initializer)

					module.values[slot] = stack.peek()

					// Remove the initializer since it should only be called once
					module.valueInitializers.removeValue(forKey: slot)
				} else {
					return runtimeError("No global found at slot: \(slot)")
				}
			case .setModuleValue:
				let slot = readByte()
				module.values[slot] = stack.peek()

				// Remove the lazy initializer for this value since we've already initialized it
				module.valueInitializers.removeValue(forKey: slot)
			case .getBuiltin:
				let slot = readByte()
				stack.push(.builtin(.init(slot)))
			case .setBuiltin:
				return runtimeError("Cannot set built in")
			case .getBuiltinStruct:
				let slot = readByte()
				stack.push(.builtinStruct(.init(slot)))
			case .setBuiltinStruct:
				return runtimeError("Cannot set built in")
			case .cast:
				let slot = readByte()
				call(structValue: .init(slot))
			case .getStruct:
				let slot = readByte()
				stack.push(.struct(.init(slot)))
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
				case let .instance(_, receiver):
					let instance = currentFrame.instances[Int(receiver)]

					if propertyOptions.contains(.isMethod) {
						// If it's a method, we create a boundMethod value, which consists of the method slot
						// and the instance ID. Using this, we can use the type we get from instance[instanceID]
						// to lookup the method.
						let boundMethod = Value.boundMethod(.init(slot), receiver)

						stack.push(boundMethod)
					} else {
						guard let value = instance.fields[Int(slot)] else {
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

				guard let (_, receiver) = instance.instanceValue else {
					return runtimeError("Receiver is not a struct: \(instance)")
				}

				currentFrame.instances[Int(receiver)].fields[Int(slot)] = propertyValue
			case .jumpPlaceholder:
				()
			}
		}
	}

	mutating func checkType(instance: Value, type: Value) {
		stack.push(.bool(instance.is(type)))
	}

	mutating func call(_ callee: Value) {
		switch callee {
		case let .closure(chunkID):
			call(closureID: Int(chunkID))
		case let .builtin(builtin):
			call(builtin: Int(builtin))
		case let .moduleFunction(moduleFunction):
			call(moduleFunction: Int(moduleFunction))
		case let .struct(structValue):
			call(structValue: .init(structValue))
		case let .boundMethod(methodSlot, instanceID):
			call(boundMethod: methodSlot, on: instanceID)
		default:
			fatalError("\(callee) is not callable")
		}
	}

	mutating func call(boundMethod methodSlot: Value.IntValue, onBuiltin instanceID: Value.IntValue) {
		stack.pop() // Pop the method off the stack

		let instance = currentFrame.builtinInstances[Int(instanceID)]
		let arity = instance.arity(for: Int(methodSlot))
		let args = stack.pop(count: arity)
		let result = instance.call(Int(methodSlot), args)

		// If the call returned a value (it's not void), push it on the stack
		if let result {
			stack.push(result)
		}
	}

	// Call a method on an instance.
	// Takes the method offset, instance and type that defines the method.
	mutating func call(boundMethod: Value.IntValue, on instanceData: Value.IntValue) {
		let instance = currentFrame.instances[Int(instanceData)]
		let structType = module.structs[Int(instance.type.structValue!)]
		let methodChunk = structType.methods[Int(boundMethod)]

		var frame = CallFrame(
			closure: .init(
				chunk: methodChunk,
				upvalues: []
			),
			returnTo: ip,
			stackOffset: 0,
			locals: .init(repeating: nil, count: Int(chunk.localsCount)),
			instances: currentFrame.instances,
			builtinInstances: currentFrame.builtinInstances
		)

		frame.locals[0] = Value.instance(
			instance.type.structValue!,
			instanceData
		)

		frames.push(frame)
	}

	mutating func call(structValue: Value.IntValue) {
		// Get the struct we're gonna be instantiating
		let structType = module.structs[Int(structValue)]

		// Figure out where in the instances "memory" the instance will live
		let instanceID = Value.IntValue(currentFrame.instances.count)

		// Create the instance Value
		let instance = Value.instance(structValue, instanceID)

		// Get the initializer
		let initializer = structType.methods[structType.initializer]

		// Store the instance value
		currentFrame.instances.append(
			StructInstance(type: .struct(structValue), fieldCount: structType.propertyCount))

		var frame = CallFrame(
			closure: .init(
				chunk: initializer,
				upvalues: []
			),
			returnTo: ip,
			stackOffset: 0,
			locals: .init(repeating: nil, count: Int(initializer.localsCount)),
			instances: currentFrame.instances,
			builtinInstances: currentFrame.builtinInstances
		)

		// The 0 index slot in locals is reserved for `self`
		frame.locals[0] = instance

		// Pass arguments into the initializer
		for (i, argument) in stack.pop(count: Int(initializer.arity)).enumerated() {
			frame.locals[i + 1] = argument
		}

		frames.push(frame)
	}

	mutating func call(chunk: Chunk) {
		var frame = CallFrame(
			closure: .init(
				chunk: chunk,
				upvalues: []
			),
			returnTo: ip,
			stackOffset: stack.size - Int(chunk.arity) - 1,
			locals: .init(repeating: nil, count: Int(chunk.localsCount)),
			instances: currentFrame.instances,
			builtinInstances: currentFrame.builtinInstances
		)

		// Pass arguments into the initializer
		for (i, argument) in stack.pop(count: Int(chunk.arity)).enumerated() {
			frame.locals[i + 1] = argument
		}


		frames.push(frame)
	}

	mutating func call(inline: Chunk) {
		let frame = CallFrame(
			closure: .init(
				chunk: inline,
				upvalues: []
			),
			returnTo: ip,
			stackOffset: stack.size - 1,
			locals: .init(repeating: nil, count: Int(chunk.localsCount)),
			instances: currentFrame.instances,
			builtinInstances: currentFrame.builtinInstances
		)

		frames.push(frame)
	}

	mutating func call(closureID: Int) {
		// Find the called chunk from the closure id
		let chunk = chunk.getChunk(at: closureID)

		var frame = CallFrame(
			closure: closures[UInt64(closureID)]!,
			returnTo: ip,
			stackOffset: stack.size - Int(chunk.arity) - 1,
			locals: .init(repeating: nil, count: Int(chunk.localsCount)),
			instances: currentFrame.instances,
			builtinInstances: currentFrame.builtinInstances
		)

		// Pass arguments into the initializer
		for (i, argument) in stack.pop(count: Int(chunk.arity)).enumerated() {
			frame.locals[i + 1] = argument
		}


		frames.push(frame)
	}

	mutating func call(chunkID: Int) {
		let chunk = chunk.getChunk(at: chunkID)
		let closure = Closure(chunk: chunk, upvalues: [])

		var frame = CallFrame(
			closure: closure,
			returnTo: ip,
			stackOffset: stack.size - Int(chunk.arity) - 1,
			locals: .init(repeating: nil, count: Int(chunk.localsCount)),
			instances: currentFrame.instances,
			builtinInstances: currentFrame.builtinInstances
		)

		// Pass arguments into the initializer
		for (i, argument) in stack.pop(count: Int(chunk.arity)).enumerated() {
			frame.locals[i + 1] = argument
		}


		frames.push(frame)
	}

	mutating func call(moduleFunction: Int) {
		let chunk = module.chunks[moduleFunction]
		let closure = Closure(chunk: chunk, upvalues: [])

		var frame = CallFrame(
			closure: closure,
			returnTo: ip,
			stackOffset: stack.size - Int(chunk.arity) - 1,
			locals: .init(repeating: nil, count: Int(chunk.localsCount)),
			instances: currentFrame.instances,
			builtinInstances: currentFrame.builtinInstances
		)

		// Pass arguments into the initializer
		for (i, argument) in stack.pop(count: Int(chunk.arity)).enumerated() {
			frame.locals[i + 1] = argument
		}


		frames.push(frame)
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
		guard let builtin = BuiltinFunction(rawValue: builtin) else {
			fatalError("no builtin at index: \(builtin)")
		}

		switch builtin {
		case .print:
			let value = stack.peek()
			print(inspect(value))
		case ._allocate:
			if case let .int(count) = stack.pop() { // Get the capacity
				let address = heap.allocate(count: Int(count))
				stack.push(.pointer(.init(address), .init(0)))
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
