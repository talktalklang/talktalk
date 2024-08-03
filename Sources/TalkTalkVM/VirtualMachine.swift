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
	var ip: UInt64 = 0

	// The code to run
	var chunk: StaticChunk

	// The frames stack
	var frames: Stack<CallFrame>

	// The stack
	var stack: Stack<Value>

	public static func run(chunk: consuming StaticChunk) -> Value {
		var vm = VirtualMachine(chunk: chunk)
		return vm.run()
	}

	public init(chunk: consuming StaticChunk) {
		self.chunk = chunk
		self.frames = Stack<CallFrame>(capacity: 256)
		self.stack = Stack<UInt64>(capacity: 256)
	}

	mutating public func run() -> Value {
		while true {
			let byte = readByte()

			guard let opcode = Opcode(rawValue: byte) else {
				fatalError("Unknown opcode: \(byte)")
			}

			switch opcode {
			case .return:
				return stack.pop()
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
				stack.push(UInt64(bitPattern: -stack.pop().asInt))
			case .not:
				stack.push(.bool(!stack.pop().asBool))
			case .equal:
				let lhs = stack.pop()
				let rhs = stack.pop()
				stack.push(.bool(lhs == rhs))
			case .notEqual:
				let lhs = stack.pop()
				let rhs = stack.pop()
				stack.push(.bool(lhs != rhs))
			case .add:
				let lhs = stack.pop()
				let rhs = stack.pop()
				stack.push(lhs + rhs)
			case .subtract:
				let lhs = stack.pop()
				let rhs = stack.pop()
				stack.push(lhs - rhs)
			case .divide:
				let lhs = stack.pop()
				let rhs = stack.pop()
				stack.push(lhs / rhs)
			case .multiply:
				let lhs = stack.pop()
				let rhs = stack.pop()
				stack.push(lhs * rhs)
			case .less:
				let lhs = stack.pop()
				let rhs = stack.pop()
				stack.push(.bool(lhs < rhs))
			case .greater:
				let lhs = stack.pop()
				let rhs = stack.pop()
				stack.push(.bool(lhs > rhs))
			case .lessEqual:
				let lhs = stack.pop()
				let rhs = stack.pop()
				stack.push(.bool(lhs <= rhs))
			case .greaterEqual:
				let lhs = stack.pop()
				let rhs = stack.pop()
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
}
