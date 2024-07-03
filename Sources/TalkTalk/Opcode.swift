//
//  Opcode.swift
//  
//
//  Created by Pat Nakajima on 6/30/24.
//

enum Opcode: Byte {
	case constant,
			 `return`,
			 negate,
			 not,
			 add, subtract, multiply, divide,
			 equal, notEqual,
			 `true`, `false`,
			 print,
			 pop,
			 defineGlobal, getGlobal,
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
