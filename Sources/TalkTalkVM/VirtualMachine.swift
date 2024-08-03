//
//  VirtualMachine.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkBytecode

struct CallFrame {
	var ip: UInt64 = 0
	var chunk: Chunk
	var returnTo: UInt64
}

public struct VirtualMachine: ~Copyable {
	public enum ExecutionResult {
		case ok(Value), error(String)

		public func get() -> Value {
			if case let .ok(value) = self {
				return value
			} else {
				fatalError("Cannot get none ok execution result")
			}
		}
	}

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
		get {
			currentFrame.chunk
		}

		set {
			currentFrame.chunk = newValue
		}
	}

	// The frames stack
	var frames: Stack<CallFrame>

	// The current call frame
	var currentFrame: CallFrame {
		get {
			frames.peek()
		}

		set {
			frames[frames.size-1] = newValue
		}
	}

	// The stack
	var stack: Stack<Value>

	public static func run(chunk: Chunk) -> ExecutionResult {
		var vm = VirtualMachine(chunk: chunk)
		return vm.run()
	}

	public init(chunk: Chunk) {
		self.stack = Stack<Value>(capacity: 256)
		self.frames = Stack<CallFrame>(capacity: 256)

		let frame = CallFrame(chunk: chunk, returnTo: 0)
		self.frames.push(frame)
	}

	mutating public func run() -> ExecutionResult {
		while true {
			let byte = readByte()

			guard let opcode = Opcode(rawValue: byte) else {
				fatalError("Unknown opcode: \(byte)")
			}

			switch opcode {
			case .return:
				frames.pop()

				if frames.size == 0 {
					return .ok(stack.pop())
				}
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
				guard let lhs = stack.pop().intValue,
							let rhs = stack.pop().intValue else {
					return runtimeError("Cannot add none int operands")
				}
				stack.push(.int(lhs + rhs))
			case .subtract:
				guard let lhs = stack.pop().intValue,
							let rhs = stack.pop().intValue else {
					return runtimeError("Cannot subtract none int operands")
				}
				stack.push(.int(lhs - rhs))
			case .divide:
				guard let lhs = stack.pop().intValue,
							let rhs = stack.pop().intValue else {
					return runtimeError("Cannot divide none int operands")
				}
				stack.push(.int(lhs / rhs))
			case .multiply:
				guard let lhs = stack.pop().intValue,
							let rhs = stack.pop().intValue else {
					return runtimeError("Cannot multiply none int operands")
				}
				stack.push(.int(lhs * rhs))
			case .less:
				guard let lhs = stack.pop().intValue,
							let rhs = stack.pop().intValue else {
					return runtimeError("Cannot compare none int operands")
				}
				stack.push(.bool(lhs < rhs))
			case .greater:
				guard let lhs = stack.pop().intValue,
							let rhs = stack.pop().intValue else {
					return runtimeError("Cannot compare none int operands")
				}
				stack.push(.bool(lhs > rhs))
			case .lessEqual:
				guard let lhs = stack.pop().intValue,
							let rhs = stack.pop().intValue else {
					return runtimeError("Cannot compare none int operands")
				}
				stack.push(.bool(lhs <= rhs))
			case .greaterEqual:
				guard let lhs = stack.pop().intValue,
							let rhs = stack.pop().intValue else {
					return runtimeError("Cannot compare none int operands")
				}
				stack.push(.bool(lhs >= rhs))
			case .data:
				let offset = stack.pop()
				stack.push(offset)
			case .pop:
				stack.pop()
			case .jump:
				self.ip += readUInt16()
			case .jumpUnless:
				let jump = readUInt16()
				if stack.peek() == .bool(false) {
					self.ip += jump
				}
			case .getLocal:
				let slot = readByte()
				stack.push(stack[Int(slot)])
			case .setLocal:
				let slot = readByte()
				stack[Int(slot)] = stack.peek()
			case .defClosure:
				// TODO: Capture closure values
				let slot = readByte()
				stack.push(.closure(slot))
			case .call:
				let callee = stack.pop()
				if callee.isCallable {
					call(callee)
				} else {
					return runtimeError("\(callee) is not callable")
				}
			case .jumpPlaceholder:
				()
			}
		}
	}

	mutating func call(_ callee: Value) {
		if let chunkID = callee.closureValue {
			call(closureID: Int(chunkID))
		}
	}

	mutating func call(closureID: Int) {
		let chunk = chunk.subchunks[closureID]
		let frame = CallFrame(chunk: chunk, returnTo: ip)

		frames.push(frame)
	}

	mutating func readConstant() -> Value {
		chunk.constants[Int(readByte())]
	}

	mutating func readByte() -> Byte {
		chunk.code[Int(ip++)]
	}

	mutating func readUInt16() -> UInt64 {
		var jump = UInt64(readByte() << 8)
		jump |= UInt64(readByte())
		return jump
	}

	func runtimeError(_ message: String) -> ExecutionResult {
		.error(message)
	}
}
