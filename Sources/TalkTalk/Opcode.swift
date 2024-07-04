//
//  Opcode.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

enum Opcode: Byte {
	// The uninitialized opcode needs to be zero, just so we have better visibility into
	// what goes wrong when the VM.ip is wrong. Otherwise, it just assumes the opcode is
	// constant which can lead to red herrings.
	case uninitialized,
	     constant,
	     `return`,
	     negate,
	     not,
	     add, subtract, multiply, divide,
	     equal, notEqual,
	     less, greater,
	     `true`, `false`,
	     print,
	     pop,
	     defineGlobal, getGlobal, setGlobal,
	     getLocal, setLocal,
	     jump,
	     // If the top of the stack is false, jumps to its operand
	     jumpIfFalse,
	     loop,
	     call,
//			 native,
	     `nil`

	var description: String {
		switch self {
		case .return:
			"OP_RETURN"
		case .constant:
			"OP_CONSTANT"
		case .negate:
			"OP_NEGATE"
		case .add:
			"OP_ADD"
		case .subtract:
			"OP_SUBTRACT"
		case .multiply:
			"OP_MULTIPLY"
		case .divide:
			"OP_DIVIDE"
		case .true:
			"OP_TRUE"
		case .false:
			"OP_FALSE"
		case .nil:
			"OP_NIL"
		case .not:
			"OP_NOT"
		default:
			"OP_\("\(self)".uppercased())"
		}
	}

	var byte: Byte {
		rawValue
	}
}
