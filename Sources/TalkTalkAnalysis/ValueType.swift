//
//  ValueType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

public indirect enum ValueType {
	public static func == (lhs: ValueType, rhs: ValueType) -> Bool {
		lhs.description == rhs.description
	}

	case int,
			 string,
			 // function name, return type, param types, captures
			 function(String, ValueType, AnalyzedParamsExpr, [Environment.Capture]),
			 bool,
			 `struct`(StructType),
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
			let captures = captures.isEmpty ? "" : "[\(captures.map(\.name).joined(separator: ", "))] "
			return "fn \(name)(\(args.params.description)) -> \(captures)(\(returnType.description))"
		case .bool:
			return "bool"
		case .error(let msg):
			return "error: \(msg)"
		case .none:
			return "none"
		case .void:
			return "void"
		case let .struct(structType):
			return "struct \(structType.name ?? "<unnamed>")"
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
