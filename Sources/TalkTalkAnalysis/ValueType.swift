//
//  ValueType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

public indirect enum ValueType: Codable {
	public static func == (lhs: ValueType, rhs: ValueType) -> Bool {
		lhs.description == rhs.description
	}

	public enum Param: Codable {
		case int(String)

		var description: String {
			switch self {
			case .int(let name):
				".int(\(name))"
			}
		}
	}

	case int,
			 string,
			 // function name, return type, param types, captures
			 function(String, ValueType, [Param], [String]),
			 bool,
			 `struct`(String),
			 instance(ValueType),
			 instanceValue(ValueType),
			 error(String),
			 none,
			 void,
			 placeholder(Int)

	public var description: String {
		switch self {
		case .int:
			return "int"
		case let .function(name, returnType, args, captures):
			let captures = captures.isEmpty ? "" : "[\(captures.joined(separator: ", "))] "
			return "fn \(name)(\(args.map(\.description).joined(separator: ", "))) -> \(captures)(\(returnType.description))"
		case .bool:
			return "bool"
		case .error(let msg):
			return "error: \(msg)"
		case .none:
			return "none"
		case .void:
			return "void"
		case let .struct(structType):
			return "struct \(structType)"
		case .placeholder:
			return "placeholder"
		case let .instance(valueType):
			return "instance \(valueType.description)"
		case let .instanceValue(structType):
			return "struct instance value \(structType)"
		case .string:
			return "string"
		}
	}
}
