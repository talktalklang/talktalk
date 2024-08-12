//
//  ValueType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

public struct InstanceValueType: Codable {
	public static func `struct`(_ name: String) -> InstanceValueType {
		InstanceValueType(ofType: .struct(name), boundGenericTypes: [:])
	}

	public var ofType: ValueType
	public var boundGenericTypes: [String: ValueType]
}

public indirect enum ValueType: Codable {
	public static func == (lhs: ValueType, rhs: ValueType) -> Bool {
		lhs.description == rhs.description
	}

	public struct Param: Codable {
		let name: String
		let type: ValueType

		public static func int(_ name: String) -> Param {
			Param(name: name, type: .int)
		}

		public var description: String {
			"\(name): \(type)"
		}
	}

	case none,
			 // primitives
			 int, string, bool,
			 // function name, return type, param types, captures
			 function(String, ValueType, [Param], [String]),
			 // struct name
			 `struct`(String),
			 // owning type of this generic, the name of the generic type
			 generic(ValueType, String),
			 instance(InstanceValueType),
			 member(ValueType),
			 error(String),
			 void,
			 placeholder(Int),
			 `any`

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
			return "instance \(valueType.ofType.description)"
		case let .member(structType):
			return "struct instance value \(structType)"
		case let .generic(owner, name):
			return "\(owner.description)<\(name)>"
		case .string:
			return "string"
		case .any:
			return "<any>"
		}
	}
}
