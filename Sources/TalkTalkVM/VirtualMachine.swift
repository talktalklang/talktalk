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

	// Where should output go? (Defaults to stdout/stderr)
	var output: any OutputBuffer

	var ip: UInt64

	// The chunk that's being run
	var chunk: StaticChunk

	// The frames stack
	var frames: DebugStack<CallFrame>
	{
		willSet {
			#if DEBUG
			if frames.size != newValue.size, frames.size > 0, verbosity != .quiet {
				log("       <- \(chunk.name), depth: \(chunk.depth) locals: \(chunk.localNames)")
			}
			#endif
		}

		didSet {
			ip = 0
			if frames.isEmpty { return }
			currentFrame = frames.peek()
			chunk = currentFrame.closure.chunk

			#if DEBUG
			if frames.size != oldValue.size, frames.size > 0, verbosity != .quiet {
				log("       -> \(chunk.name), depth: \(chunk.depth) locals: \(chunk.localNames) stack offset: \(currentFrame.stackOffset)")
			}
			#endif
		}
	}

	// The current call frame
	var currentFrame: CallFrame

	// The stack
	var stack: DebugStack<Value>

	// A fake heap
	var heap = Heap()

	// Closure storage
	var closures: [UInt64: Closure] = [:]

	var globalValues: [Byte: Value] = [:]

	// Upvalue linked list
	var openUpvalues: Upvalue?
	public static func run(module: Module, verbosity: Verbosity = .quiet, output: any OutputBuffer = DefaultOutputBuffer()) -> ExecutionResult {
		var vm = VirtualMachine(module: module, verbosity: verbosity, output: output)
		return vm.run()
	}

	public init(
		module: Module,
		verbosity: Verbosity = .quiet,
		output: any OutputBuffer = DefaultOutputBuffer()
	) {
		self.module = module
		self.verbosity = verbosity
		self.output = output

		guard let chunk = module.main else {
			fatalError("no entrypoint found for module `\(module.name)`")
		}

		self.stack = DebugStack<Value>(capacity: 256)
		self.frames = DebugStack<CallFrame>(capacity: 256)

		// Reserving this space
		stack.push(.reserved)

		let frame = CallFrame(
			closure: Closure(chunk: chunk, upvalues: []),
			returnTo: 0,
			stackOffset: 0
		)

		frames.push(frame)
		self.currentFrame = frame
		self.chunk = frame.closure.chunk
		self.ip = 0
	}

	public mutating func run() -> ExecutionResult {
		while true {
			#if DEBUG
				func dumpInstruction() -> Instruction? {
					var disassembler = Disassembler(chunk: chunk, module: module)
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
							FileHandle.standardError.write(Data(("       " + line + "\n").utf8))
						} else {
							var line = ""
							if let url = URL(string: "file://" + i.path),
								 let filelines = try? String(contentsOf: url).components(separatedBy: .newlines) {
								line = filelines[Int(i.line)] + " "
							}
							FileHandle.standardError.write(Data("        \(line)<\(i.path.components(separatedBy: "/").last ?? i.path):\(i.line)>\n".utf8))
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
						heap.store(pointer: pointer + i, value: Value.byte(bytes[i]))
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
				let lhs = stack.pop()
				let rhs = stack.pop()

				guard let lhs = lhs.intValue,
				      let rhs = rhs.intValue
				else {
					return runtimeError("Cannot compare \(lhs) & \(rhs) operands")
				}
				stack.push(.bool(lhs < rhs))
			case .greater:
				let lhs = stack.pop()
				let rhs = stack.pop()

				guard let lhs = lhs.intValue,
							let rhs = rhs.intValue
				else {
					return runtimeError("Cannot compare \(lhs) & \(rhs) operands")
				}
				stack.push(.bool(lhs > rhs))
			case .lessEqual:
				let lhs = stack.pop()
				let rhs = stack.pop()

				guard let lhs = lhs.intValue,
							let rhs = rhs.intValue
				else {
					return runtimeError("Cannot compare \(lhs) & \(rhs) operands")
				}
				stack.push(.bool(lhs <= rhs))
			case .greaterEqual:
				let lhs = stack.pop()
				let rhs = stack.pop()

				guard let lhs = lhs.intValue,
							let rhs = rhs.intValue
				else {
					return runtimeError("Cannot compare \(lhs) & \(rhs) operands")
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
				stack.push(stack[Int(slot) + currentFrame.stackOffset])
			case .setLocal:
				let slot = readByte()
				stack[Int(slot) + currentFrame.stackOffset] = stack.peek()
			case .getUpvalue:
				let slot = readByte()
				let value = currentFrame.closure.upvalues[Int(slot)].value
				stack.push(value)
			case .setUpvalue:
				let slot = readByte()
				let upvalue = currentFrame.closure.upvalues[Int(slot)]
				upvalue.value = stack.peek()
			case .defClosure:
				// Read which subchunk this closure points to
				let slot = readByte()

				// Load the subchunk TODO: We could probably just store the index in the closure?
				let subchunk = module.chunks[Int(slot)]

				// Push the closure Value onto the stack
				stack.push(.closure(.init(slot)))

				// Capture upvalues
				var upvalues: [Upvalue] = []
				for _ in 0 ..< subchunk.upvalueCount {
					let isLocal = readByte() == 1
					let index = readByte()

					if isLocal {
						// If the upvalue is local, that means it is defined in the current call frame. That
						// means we want to capture the value.
						let value = stack[currentFrame.stackOffset + Int(index)]
						let upvalue = captureUpvalue(value: value)
						upvalues.append(upvalue)
					} else {
						// If it's not local, that means it's already been captured and the current call frame's
						// knowledge of the value is an upvalue as well.
						upvalues.append(currentFrame.closure.upvalues[Int(index)])
					}
				}

				// Store the closure TODO: gc these when they're not needed anymore
				closures[UInt64(slot)] = Closure(chunk: subchunk, upvalues: upvalues)
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
				let moduleFunction = Value.moduleFunction(.init(slot))
				stack.push(moduleFunction)
			case .setModuleFunction:
				return runtimeError("cannot set module functions")
			case .getModuleValue:
				let slot = readByte()
				if let global = globalValues[slot] {
					stack.push(global)
				} else if let initializer = module.valueInitializers[slot] {
					// If we don't have the global already, we lazily initialize it by running its initializer
					call(chunk: initializer)

					globalValues[slot] = stack.peek()

					// Remove the initializer since it should only be called once
					module.valueInitializers.removeValue(forKey: slot)
				} else {
					return runtimeError("No global found at slot: \(slot)")
				}
			case .setModuleValue:
				let slot = readByte()
				globalValues[slot] = stack.peek()

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
				call(structValue: module.structs[Int(slot)])
			case .getStruct:
				let slot = readByte()
				stack.push(.struct(module.structs[Int(slot)]))
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
				case let .instance(instance):
					if propertyOptions.contains(.isMethod) {
						// If it's a method, we create a boundMethod value, which consists of the method slot
						// and the instance ID. Using this, we can use the type we get from instance[instanceID]
						// to lookup the method.
						let boundMethod = Value.boundMethod(instance, .init(slot))

						stack.push(boundMethod)
					} else {
						guard let value = instance.fields[Int(slot)] else {
							return runtimeError("uninitialized value in slot \(slot) for \(instance)")
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

				guard let (receiver) = instance.instanceValue else {
					return runtimeError("Receiver is not a struct: \(instance)")
				}

				// Set the property
				receiver.fields[Int(slot)] = propertyValue

				// Put the updated instance back onto the stack
				stack[stack.size - 1] = .instance(receiver)
			case .jumpPlaceholder:
				()
			case .get:
				let instance = stack.pop()
				guard let (receiver) = instance.instanceValue else {
					return runtimeError("Receiver is not a struct: \(instance)")
				}

				// TODO: Make this user-implementable
				let getSlot = receiver.type.methods.firstIndex(where: { $0.name.contains("$get$") })!
				call(boundMethod: getSlot, on: receiver)
			case .initArray:
				let count = readByte()

				// We need to set the capacity to at least 1 or else trying to resize it will multiply 0 by 2
				// which means we never actually get more capacity.
				let capacity = max(count, 1)
				let arrayTypeSlot = module.symbols[.struct("Standard", "Array")]!.slot
				let arrayType = module.structs[arrayTypeSlot]

				let pointer = heap.allocate(count: Int(capacity))
				for i in 0..<count {
					heap.store(pointer: pointer + Int(i), value: stack.pop())
				}

				let instance = Instance(type: arrayType, fields: [
					.pointer(pointer),
					.int(.init(count)),
					.int(.init(capacity))
				])

				stack.push(.instance(instance))
			case .initDict: ()
				let dictTypeSlot = module.symbols[.struct("Standard", "Dictionary")]!.slot
				let dictType = module.structs[dictTypeSlot]

				call(structValue: dictType)
			}
		}
	}

	private mutating func checkType(instance: Value, type: Value) {
		stack.push(.bool(instance.is(type)))
	}

	private mutating func call(_ callee: Value) {
		switch callee {
		case let .closure(chunkID):
			call(closureID: Int(chunkID))
		case let .builtin(builtin):
			call(builtin: Int(builtin))
		case let .moduleFunction(moduleFunction):
			call(moduleFunction: Int(moduleFunction))
		case let .struct(structValue):
			call(structValue: structValue)
		case let .boundMethod(instance, slot):
			call(boundMethod: slot, on: instance)
		default:
			fatalError("\(callee) is not callable")
		}
	}

	// Call a method on an instance.
	// Takes the method offset, instance and type that defines the method.
	private mutating func call(boundMethod: Int, on instance: Instance) {
		let methodChunk = instance.type.methods[Int(boundMethod)]
		stack[stack.size - Int(methodChunk.arity) - 1] = .instance(instance)
		call(chunk: methodChunk)
	}

	private mutating func call(structValue structType: Struct) {
		// Create the instance Value
		let instance = Value.instance(
			Instance(
				type: structType,
				fields: Array(repeating: nil, count: structType.propertyCount)
			)
		)

		// Get the initializer
		guard let slot = structType.initializerSlot else {
			fatalError("no initializer found for \(structType.name)")
		}

		let initializer = structType.methods[slot]

		// Add the instance to the stack
		stack[stack.size - Int(initializer.arity) - 1] = instance

		call(chunk: initializer)
	}

	private mutating func call(chunk: StaticChunk) {
		let frame = CallFrame(
			closure: .init(
				chunk: chunk,
				upvalues: []
			),
			returnTo: ip,
			stackOffset: stack.size - Int(chunk.arity) - 1
		)

		frames.push(frame)
	}

	private mutating func call(closureID: Int) {
		// Find the called chunk from the closure id
		let chunk = module.chunks[closureID]

		let frame = CallFrame(
			closure: closures[UInt64(closureID)]!,
			returnTo: ip,
			stackOffset: stack.size - Int(chunk.arity) - 1
		)

		frames.push(frame)
	}

	private mutating func call(chunkID: Int) {
		let chunk = module.chunks[chunkID]
		let closure = Closure(chunk: chunk, upvalues: [])

		let frame = CallFrame(
			closure: closure,
			returnTo: ip,
			stackOffset: stack.size - Int(chunk.arity) - 1
		)

		frames.push(frame)
	}

	private mutating func call(moduleFunction: Int) {
		let chunk = module.chunks[moduleFunction]
		let closure = Closure(chunk: chunk, upvalues: [])

		let frame = CallFrame(
			closure: closure,
			returnTo: ip,
			stackOffset: stack.size - Int(chunk.arity) - 1
		)

		frames.push(frame)
	}

	private func inspect(_ value: Value) -> String {
		switch value {
		case let .string(string):
			string
		case let .int(int):
			"\(int)"
		default:
			value.description
		}
	}

	private mutating func call(builtin: Int) {
		guard let builtin = BuiltinFunction(rawValue: builtin) else {
			fatalError("no builtin at index: \(builtin)")
		}

		switch builtin {
		case .print:
			let value = stack.peek()
			do {
				let string = inspect(value) + "\n"
				try output.write([Byte](Data(string.utf8)), to: .stdout)
			} catch {
				fatalError("Error writing output: \(error)")
			}
		case ._allocate:
			if case let .int(count) = stack.pop() { // Get the capacity
				let pointer = heap.allocate(count: Int(count))
				stack.push(.pointer(pointer))
			}
		case ._deref:
			if case let .pointer(pointer) = stack.pop(),
				 let value = heap.dereference(pointer: pointer)
			{
				stack.push(value)
			}
		case ._free:
			() // TODO:
		case ._storePtr:
			let value = stack.pop()
			if case let .pointer(pointer) = stack.pop() {
				heap.store(pointer: pointer, value: value)
			}
		case ._hash:
			let value = stack.pop()
			stack.push(.int(.init(value.hashValue)))
		case ._cast:
			stack.pop()
			stack.pop()
			() // This is just for the analyzer
		}
	}

	private mutating func readConstant() -> Value {
		let value = chunk.constants[Int(readByte())]
		return value
	}

	private mutating func readByte() -> Byte {
		defer { ip += 1 }
		return chunk.code[Int(ip)]
	}

	private mutating func readUInt16() -> UInt64 {
		var jump = UInt64(readByte() << 8)
		jump |= UInt64(readByte())
		return jump
	}

	private mutating func captureUpvalue(value: Value) -> Upvalue {
		var previousUpvalue: Upvalue? = nil
		var upvalue = openUpvalues

		while upvalue != nil /* , upvalue!.value > value */ {
			previousUpvalue = upvalue
			upvalue = upvalue!.next
		}

		if let upvalue, upvalue.value == value {
			return upvalue
		}

		let createdUpvalue = Upvalue(value: value)
		createdUpvalue.next = upvalue

		if let previousUpvalue {
			previousUpvalue.next = createdUpvalue
		} else {
			openUpvalues = createdUpvalue
		}

		return createdUpvalue
	}

	private func runtimeError(_ message: String) -> ExecutionResult {
		.error(message)
	}

	@discardableResult private mutating func dumpStack() -> String {
		if stack.isEmpty { return "" }
		var result = "       "

		if currentFrame.stackOffset > 0 {
			result += "[ \(currentFrame.stackOffset) skipped ]"
		}

		for slot in stack.entries()[currentFrame.stackOffset..<stack.size] {
			if frames.size == 0 {
				result += "[ \(slot.description) ]"
			} else {
				result += "[ \(slot.disassemble(in: module)) ]"
			}
		}

		FileHandle.standardError.write(Data((result + "\n").utf8))

		return result
	}

	private mutating func dump() {
		var disassembler = Disassembler(chunk: chunk, module: module)
		for instruction in disassembler.disassemble() {
			let prefix = instruction.offset == ip ? "> " : "  "
			print(prefix + instruction.description)

			if instruction.offset == ip {
				dumpStack()
			}
		}
	}

	private func log(_ string: String) {
		FileHandle.standardError.write(Data((string + "\n").utf8))
	}
}
