//
//  VirtualMachine.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import TalkTalkBytecode

struct CallFrame {

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

	var ip: UInt64 = 0

	// The code to run
	var chunk: StaticChunk

	// The frames stack
	var frames: Stack<CallFrame>

	// The stack
	var stack: Stack<Value>

	public static func run(chunk: consuming StaticChunk) -> ExecutionResult {
		var vm = VirtualMachine(chunk: chunk)
		return vm.run()
	}

	public init(chunk: consuming StaticChunk) {
		self.chunk = chunk
		self.frames = Stack<CallFrame>(capacity: 256)
		self.stack = Stack<Value>(capacity: 256)
	}

	mutating public func run() -> ExecutionResult {
		while true {
			let byte = readByte()

			guard let opcode = Opcode(rawValue: byte) else {
				fatalError("Unknown opcode: \(byte)")
			}

			switch opcode {
			case .return:
				return .ok(stack.pop())
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
			}
		}
	}

	mutating func readConstant() -> Value {
		chunk.constants[Int(readByte())]
	}

	mutating func readByte() -> Byte {
		chunk.code[Int(ip++)]
	}

	func runtimeError(_ message: String) -> ExecutionResult {
		.error(message)
	}
}
