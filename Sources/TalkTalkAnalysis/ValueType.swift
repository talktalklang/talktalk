//
//  ValueType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode

public struct InstanceValueType: Codable, Equatable, Hashable, Sendable {
	public static func ==(lhs: InstanceValueType, rhs: InstanceValueType) -> Bool {
		lhs.ofType == rhs.ofType && lhs.boundGenericTypes == rhs.boundGenericTypes
	}

	public static func `struct`(_ name: String, _ boundGenericTypes: [String: TypeID] = [:]) -> InstanceValueType {
		InstanceValueType(ofType: .struct(name), boundGenericTypes: boundGenericTypes)
	}

	public var ofType: ValueType
	public var boundGenericTypes: [String: TypeID]

	public init(ofType: ValueType, boundGenericTypes: [String: TypeID]) {
		self.ofType = ofType
		self.boundGenericTypes = boundGenericTypes
	}

	public func assignableTo(_ other: Any) -> Bool {
		if let other = other as? InstanceValueType {
			return other.ofType.isAssignable(from: ofType) &&
				other.boundGenericTypes.keys.sorted() == boundGenericTypes.keys.sorted() &&
			other.boundGenericTypes.allSatisfy({ (name, typeID) in
				guard let ourType = boundGenericTypes[name]?.current else { return false }
				return typeID.current.isAssignable(from: ourType)
			})
		}

		return false
	}
}

public indirect enum ValueType: Codable, Equatable, Hashable, Sendable {
	public static func == (lhs: ValueType, rhs: ValueType) -> Bool {
		lhs.description == rhs.description
	}

	public struct Param: Codable, Hashable, CustomStringConvertible, Typed, Sendable {
		public let name: String
		public let typeID: TypeID

		public static func int(_ name: String) -> Param {
			Param(name: name, typeID: TypeID(.int))
		}

		public var description: String {
			"\(name): \(typeID.type())"
		}
	}

	case none,
	     // primitives
	     int, bool, byte,
	     // pointer to a spot on the "heap"
	     pointer,
	     // function name, return type, param types, captures
	     function(String, TypeID, [Param], [String]),
	     // struct name
	     `struct`(String),
	     // owning type of this generic, the name of the generic type
	     generic(ValueType, String),
	     instance(InstanceValueType),
	     member(ValueType),
	     error(String),
	     void,
	     placeholder,
	     any

	public var description: String {
		switch self {
		case .byte:
			return "byte"
		case .int:
			return "int"
		case let .function(name, returnType, args, captures):
			let captures = captures.isEmpty ? "" : "[\(captures.joined(separator: ", "))] "
			return "fn \(name)(\(args.map(\.description).joined(separator: ", "))) -> \(captures)(\(returnType))"
		case .bool:
			return "bool"
		case let .error(msg):
			return "error: \(msg)"
		case .none:
			return "none"
		case .void:
			return "void"
		case let .struct(structType):
			return "\(structType)"
		case .placeholder:
			return "placeholder"
		case let .instance(valueType):
			if valueType.boundGenericTypes.isEmpty {
				return "\(valueType.ofType.description) instance"
			} else {
				return "\(valueType.ofType.description) instance (\(valueType.boundGenericTypes.sorted(by: { $0.key.description < $1.key.description })))"
			}
		case let .member(structType):
			return "struct instance value \(structType)"
		case let .generic(owner, name):
			return "\(owner.description)<\(name)>"
		case .pointer:
			return "pointer"
		case .any:
			return "<any>"
		}
	}

	public var primitive: Primitive? {
		switch self {
		case .none:
			Primitive.none
		case .int:
			.int
		case .bool:
			.bool
		case .byte:
			.byte
		case .pointer:
			.pointer
		case .struct("String"):
			.string
		default:
			nil
		}
	}

	var specificity: Int {
		switch self {
		case .pointer:
			2
		case let .generic(valueType, _):
			valueType.specificity + 1
		case .placeholder:
			0
		case .any:
			1
		default:
			3
		}
	}

	public func isAssignable(from other: ValueType) -> Bool {
		switch self {
		case .none:
			return false
		case .int:
			return other == .int
		case .bool:
			return other == .bool
		case .byte:
			return other == .byte
		case .pointer:
			return other == .pointer
		case let .function(_, typeID, params, _):
			guard case let .function(_, otherID, otherParams, _) = other else {
				return false
			}

			return typeID == otherID && params == otherParams
		case let .struct(string):
			return other == .struct(string)
		case let .generic(valueType, string):
			return true // TODO: Be more stringent here
		case let .instance(instanceValueType):
			if case let .instance(otherInstanceValueType) = other {
				return otherInstanceValueType.assignableTo(instanceValueType)
			}

			return false
		case let .member(valueType):
			return other == .member(valueType)
		case .error:
			return false
		case .void:
			return false
		case .placeholder:
			return true
		case .any:
			return true
		}
	}
}
