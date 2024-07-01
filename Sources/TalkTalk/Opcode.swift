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
			 add, subtract, multiply, divide

	var description: String {
		switch self {
		case .constant:
			"OP_CONSTANT"
		case .return:
			"OP_RETURN"
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
		}
	}
}
