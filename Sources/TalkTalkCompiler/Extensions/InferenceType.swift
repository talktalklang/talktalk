//
//  InferenceType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/20/24.
//

import TalkTalkBytecode
import TypeChecker

extension InferenceType {
	func symbol(in generator: SymbolGenerator, name: String? = nil, source: SymbolInfo.Source) throws -> Symbol {
		switch self {
		case .base(let primitive):
			return switch primitive {
			case .int: .primitive("int")
			case .string:	.primitive("string")
			case .bool:	.primitive("bool")
			case .pointer: .primitive("pointer")
			case .nope:	.primitive("none")
			}
		case .function(let params, let returns):
			return generator.function(name ?? "<unnamed>", parameters: params.map(\.description), returns: returns.description, source: source)
		case .instantiatable(let instantiatableType):
			switch instantiatableType {
			case .struct(let structType):
				return generator.struct(structType.name, source: source)
			case .enumType(let enumType):
				return generator.enum(enumType.name, source: source)
			case .protocol(let protocolType):
				return generator.protocol(protocolType.name, source: source)
			}
		case .enumCase(let enumCase):
			return generator.property(enumCase.type.name, enumCase.name, source: source)
		default:
			throw CompilerError.typeError("Could not generate symbol from inference type: \(self)")
		}
	}
}
