//
//  VirtualMachine.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkBytecode

public struct VirtualMachine: ~Copyable {
	public enum ExecutionResult {
		case ok(Value), error(String)

		public func error() -> String? {
			switch self {
			case .ok(let value):
				return nil
			case .error(let string):
				return string
			}
		}

		public func get() -> Value {
			switch self {
			case .ok(let value):
				return value
			case .error(let string):
				fatalError("Execution error: \(string)")
			}
		}
	}

	var module: Module

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
	var frames: Stack<CallFrame>

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

	// Closure storage
	var closures: [UInt64: Closure] = [:]

	// Upvalue linked list
	var openUpvalues: Upvalue?

	// So we can retain stuff
	var memory: [Value] = []

	public static func run(module: Module) -> ExecutionResult {
		var vm = VirtualMachine(module: module)
		return vm.run()
	}

	public init(module: Module) {
		self.module = module
		let chunk = module.main

		self.stack = Stack<Value>(capacity: 256)
		self.frames = Stack<CallFrame>(capacity: 256)

		stack.push(.none)

		// FIXME:
		let frame = CallFrame(closure: Closure(chunk: chunk, upvalues: []), returnTo: 0, stackOffset: 0)
		frames.push(frame)
	}

	public mutating func run() -> ExecutionResult {
		while true {
//			#if DEBUG
//			var disassembler = Disassembler(chunk: chunk)
//			disassembler.current = Int(ip)
//			if let instruction = disassembler.next() {
//				dumpStack()
//				print(instruction.description)
//			}
//			#endif

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
				while stack.size > calledFrame.stackOffset+1 {
					stack.pop()
				}

				// If there are no frames left, we're done.
				if frames.size == 0 {
					// Make sure we didn't leak anything, we should only have the main program
					// on the stack.
					if stack.size != 1 {
						print("stack size expected to be 0, got: \(stack.size)")
						dumpStack()
					}

					return .ok(result)
				}

				// Push the result back onto the stack
				stack.push(result)

				// Return to where we called from
				ip = calledFrame.returnTo
			case .constant:
				let value = readConstant()
				stack.push(value)
			case .true:
				stack.push(.bool(true))
			case .false:
				stack.push(.bool(false))
			case .none:
				stack.push(.none)
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

				guard let lhs = lhsValue.intValue,
							let rhs = rhsValue.intValue
				else {
					return runtimeError("Cannot add \(lhsValue) to \(rhsValue) operands")
				}
				stack.push(.int(lhs + rhs))
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
				let offset = stack.pop()
				stack.push(offset)
			case .pop:
				stack.pop()
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
				let subchunk = chunk.getChunk(at: Int(slot))

				// Capture upvalues
				var upvalues: [Upvalue] = []
				for _ in 0..<subchunk.upvalueCount {
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

				// Push the closure Value onto the stack
				stack.push(.closure(slot))
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
			case .getGlobal:
				let slot = readByte()
				if let global = module.globals[slot] {
					stack.push(global)
				} else {
					return runtimeError("No global found at slot: \(slot)")
				}
			case .setGlobal:
				let slot = readByte()
				module.globals[slot] = stack.peek()
			case .getBuiltin:
				let slot = readByte()
				stack.push(.builtin(slot))
			case .setBuiltin:
				return runtimeError("Cannot set built in")
			case .jumpPlaceholder:
				()
			}
		}
	}

	mutating func call(_ callee: Value) {
		if let chunkID = callee.closureValue {
			call(closureID: Int(chunkID))
		} else if let builtin = callee.builtinValue {
			call(builtin: Int(builtin))
		} else if let moduleFunction = callee.moduleFunctionValue {
			call(moduleFunction: Int(moduleFunction))
		}
	}

	mutating func call(closureID: Int) {
		// Find the called chunk from the closure id
		let chunk = chunk.getChunk(at: closureID)

		let frame = CallFrame(
			closure: closures[UInt64(closureID)]!,
			returnTo: ip,
			stackOffset: stack.size - Int(chunk.arity) - 1
		)

		frames.push(frame)
	}

	mutating func call(chunkID: Int) {
		let chunk = chunk.getChunk(at: chunkID)
		let closure = Closure(chunk: chunk, upvalues: [])

		let frame = CallFrame(
			closure: closure,
			returnTo: ip,
			stackOffset: stack.size - Int(chunk.arity) - 1
		)

		frames.push(frame)
	}

	mutating func call(moduleFunction: Int) {
		let chunk = module.chunks[moduleFunction]
		let closure = Closure(chunk: chunk, upvalues: [])

		let frame = CallFrame(
			closure: closure,
			returnTo: ip,
			stackOffset: stack.size - Int(chunk.arity) - 1
		)

		frames.push(frame)
	}

	mutating func call(builtin: Int) {
		guard let builtin = Builtin(rawValue: builtin) else {
			fatalError("no builtin at index: \(builtin)")
		}

		switch builtin {
		case .print:
			print(stack.peek())
		}
	}

	mutating func readConstant() -> Value {
		let value = chunk.constants[Int(readByte())]
		memory.append(value)
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

	mutating func captureUpvalue(value: Value) -> Upvalue {
		var previousUpvalue: Upvalue? = nil
		var upvalue = openUpvalues

		while upvalue != nil, upvalue!.value.asUInt64 > value.asUInt64 {
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
			self.openUpvalues = createdUpvalue
		}

		return createdUpvalue
	}

	func runtimeError(_ message: String) -> ExecutionResult {
		.error(message)
	}

	mutating func dumpStack() {
		if stack.isEmpty { return }
		print("       ", terminator: "")
		for slot in stack.entries() {
			if frames.size == 0 {
				print("[ \(slot.description) ]", terminator: "")
			} else {
				print("[ \(slot.disassemble(in: chunk)) ]", terminator: "")
			}
		}
		print()
	}
}
