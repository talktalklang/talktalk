//
//  InstanceType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/19/24.
//
import OrderedCollections

public enum InstanceType {
	public func equals(_ rhs: InstanceType) -> Bool {
		switch (self, rhs) {
		case let (.struct(l), .struct(r)):
			l.type == r.type && l.substitutions.keys == r.substitutions.keys
		case let (.enumType(l), .enumType(r)):
			l.type == r.type && l.substitutions.keys == r.substitutions.keys
		case let (.protocol(l), .protocol(r)):
			l.type == r.type && l.substitutions.keys == r.substitutions.keys
		default:
			false
		}
	}

	case `struct`(InstanceV1<StructTypeV1>)
	case `protocol`(InstanceV1<ProtocolType>)
	case enumType(InstanceV1<EnumTypeV1>)

	public static func synthesized(_ type: some InstantiatableV1) -> InstanceType {
		// swiftlint:disable force_cast
		switch type {
		case is StructTypeV1:
			.struct(.synthesized(type as! StructTypeV1))
		case is ProtocolType:
			.protocol(.synthesized(type as! ProtocolType))
		case is EnumTypeV1:
			.enumType(.synthesized(type as! EnumTypeV1))
		default:
			// swiftlint:disable fatal_error
			fatalError("unable to synthesize instance type: \(type)")
			// swiftlint:enable fatal_error
		}
		// swiftlint:enable force_cast
	}

	func relatedType(named name: String) -> InferenceType? {
		switch self {
		case let .struct(instance):
			instance.relatedType(named: name)
		case let .protocol(instance):
			instance.relatedType(named: name)
		case let .enumType(instance):
			instance.relatedType(named: name)
		}
	}

	var substitutions: OrderedDictionary<TypeVariable, InferenceType> {
		get {
			switch self {
			case let .struct(instance):
				instance.substitutions
			case let .protocol(instance):
				instance.substitutions
			case let .enumType(instance):
				instance.substitutions
			}
		}

		set {
			switch self {
			case let .struct(instance):
				instance.substitutions = newValue
			case let .protocol(instance):
				instance.substitutions = newValue
			case let .enumType(instance):
				instance.substitutions = newValue
			}
		}
	}

	func extract<T: InstantiatableV1>(_: T.Type) -> InstanceV1<T>? {
		switch self {
		case let .struct(instance):
			instance as? InstanceV1<T>
		case let .protocol(instance):
			instance as? InstanceV1<T>
		case let .enumType(instance):
			instance as? InstanceV1<T>
		}
	}

	public func member(named name: String, in context: InferenceContext) -> InferenceType? {
		switch self {
		case let .struct(instance):
			instance.member(named: name, in: context)
		case let .protocol(instance):
			instance.member(named: name, in: context)
		case let .enumType(instance):
			instance.member(named: name, in: context)
		}
	}

	// Returns a method with no substitutions applied
	public func genericMethod(named name: String) -> InferenceType? {
		let result = switch self {
		case let .struct(instance):
			instance.type.methods[name]
		case let .protocol(instance):
			instance.type.methods[name]
		case let .enumType(instance):
			instance.type.methods[name]
		}

		guard let result else { return nil }

		switch result {
		case let .type(type):
			return type
		case let .scheme(scheme):
			return scheme.type
		}
	}


	public var type: any InstantiatableV1 {
		switch self {
		case let .struct(instance):
			instance.type
		case let .protocol(instance):
			instance.type
		case let .enumType(instance):
			instance.type
		}
	}
}

extension InstanceType: CustomStringConvertible {
	public var description: String {
		switch self {
		case let .struct(instance):
			instance.description
		case let .protocol(instance):
			instance.description
		case let .enumType(instance):
			instance.description
		}
	}
}

extension InstanceType: CustomDebugStringConvertible {
	public var debugDescription: String {
		description
	}
}

extension InstanceType: Equatable {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case let (.enumType(lhs), .enumType(rhs)):
			return lhs == rhs
		case let (.struct(lhs), .struct(rhs)):
			return lhs == rhs
		case let (.protocol(lhs), .protocol(rhs)):
			return lhs == rhs
		default: ()
		}

		return false
	}
}
