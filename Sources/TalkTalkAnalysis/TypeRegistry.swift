//
//  TypeRegistry.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/12/24.
//

import Foundation
import TalkTalkSyntax

// The typeID is a reference wrapper around a ValueType. This way
// we don't need to embed type data into the types themselves.
//
// The main idea here is that types should be able to be updated any
// time new information becomes available. Also multiple things that
// are known to have the same type should get updated when you update one
// of them.
public final class TypeID: Codable, Hashable, Equatable, CustomStringConvertible, @unchecked Sendable {
	public static func == (lhs: TypeID, rhs: TypeID) -> Bool {
		lhs.id == rhs.id
	}

	// The current known value type of this type ID
	private(set) public var current: ValueType

	// If this type is being inferred from another type ID, it is stored as inferredFrom
	private var inferredFrom: TypeID?

	// If this type is being inferred from by any other type IDs, they ared stored in here so they
	// can be updated if this type id is updated
	private var inferrenceChildren: Set<TypeID> = []

	// Can this type ID be updated?
	private var immutable: Bool = false

	var id: UUID

	public init(inferredFrom: TypeID) {
		self.id = UUID()
		self.current = inferredFrom.type()
		self.inferredFrom = inferredFrom
	}

	public init(_ initial: ValueType = .placeholder, immutable: Bool = false) {
		self.id = UUID()
		self.current = initial
		self.immutable = immutable
	}

	public func infer(from other: TypeID) {
		if immutable {
			fatalError("cannot set inference on immutable typeID")
		}
//		assert(inferredFrom == nil, "inferredFrom is already set to \(inferredFrom!.description), was attempting to set to \(other.description)")

		// Set our own inferred from
		inferredFrom = other
		other.inferrenceChildren.insert(self)
		self.current = other.current
	}

	public func type() -> ValueType {
		current
	}

	public func update(_ type: ValueType, from child: TypeID? = nil, location: SourceLocation) -> [AnalysisError] {
		current = type

		var errors: [AnalysisError] = []

		if let inferredFrom {
			errors.append(contentsOf: inferredFrom.update(type, from: self, location: location))
		}

		for inferrenceChild in inferrenceChildren {
			if let child, child == self { continue }

			if !inferrenceChild.type().isAssignable(from: type) {
				errors.append(AnalysisError(kind: .typeCannotAssign(expected: inferrenceChild, received: self), location: location))
			}

			inferrenceChild.current = type
		}

		return errors
	}

	// Try to resolve generic types to concrete types based on instance bindings
	public func resolve(with instance: InstanceValueType) -> TypeID {
		guard case let .generic(instance.ofType, typeParam) = current else {
			return self
		}

		return instance.boundGenericTypes[typeParam] ?? self
	}

	public var description: String {
		let typeDescription = switch current {
		case .none:
			"nope"
		case .int:
			"int"
		case .bool:
			"bool"
		case .byte:
			"byte"
		case .pointer:
			"pointer"
		case let .function(_, typeID, array, _):
			"func(\(array)) -> \(typeID.description)"
		case let .struct(string):
			string + ".Type"
		case let .generic(valueType, string):
			"\(valueType)<\(string)>"
		case let .instance(instanceValueType):
			switch instanceValueType.ofType {
			case let .struct(name): name
			default: instanceValueType.ofType.description
			}
		case let .member(valueType):
			"\(valueType) member"
		case let .error(string):
			string
		case .void:
			"void"
		case .placeholder:
			"<unknown>"
		case .any:
			"any"
		}

		return "TypeID -> " + typeDescription
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(current)
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.id = try container.decode(UUID.self, forKey: .id)
		self.current = try container.decode(ValueType.self, forKey: .current)
	}
}
