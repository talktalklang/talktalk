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
		case (.struct(let l), .struct(let r)):
			return l.type == r.type && l.substitutions.keys == r.substitutions.keys
		case (.enumType(let l), .enumType(let r)):
			return l.type == r.type && l.substitutions.keys == r.substitutions.keys
		case (.protocol(let l), .protocol(let r)):
			return l.type == r.type && l.substitutions.keys == r.substitutions.keys
		default:
			return false
		}
	}

	case `struct`(Instance<StructType>)
	case `protocol`(Instance<ProtocolType>)
	case `enumType`(Instance<EnumType>)

	public static func synthesized<T: Instantiatable>(_ type: T) -> InstanceType {
		// swiftlint:disable force_cast
		switch type {
		case is StructType:
			return .struct(.synthesized(type as! StructType))
		case is ProtocolType:
			return .protocol(.synthesized(type as! ProtocolType))
		case is EnumType:
			return .enumType(.synthesized(type as! EnumType))
		default:
			// swiftlint:disable fatal_error
			fatalError("unable to synthesize instance type: \(type)")
			// swiftlint:enable fatal_error
		}
		// swiftlint:enable force_cast
	}

	func relatedType(named name: String) -> InferenceType? {
		switch self {
		case .struct(let instance):
			return instance.relatedType(named: name)
		case .protocol(let instance):
			return instance.relatedType(named: name)
		case .enumType(let instance):
			return instance.relatedType(named: name)
		}
	}

	var substitutions: OrderedDictionary<TypeVariable, InferenceType> {
		get {
			switch self {
			case .struct(let instance):
				return instance.substitutions
			case .protocol(let instance):
				return instance.substitutions
			case .enumType(let instance):
				return instance.substitutions
			}
		}

		set {
			switch self {
			case .struct(let instance):
				instance.substitutions = newValue
			case .protocol(let instance):
				instance.substitutions = newValue
			case .enumType(let instance):
				instance.substitutions = newValue
			}
		}
	}

	func extract<T: Instantiatable>(_ type: T.Type) -> Instance<T>? {
		switch self {
		case .struct(let instance):
			return instance as? Instance<T>
		case .protocol(let instance):
			return instance as? Instance<T>
		case .enumType(let instance):
			return instance as? Instance<T>
		}
	}

	public func member(named name: String, in context: InferenceContext) -> InferenceType? {
		switch self {
		case .struct(let instance):
			return instance.member(named: name, in: context)
		case .protocol(let instance):
			return instance.member(named: name, in: context)
		case .enumType(let instance):
			return instance.member(named: name, in: context)
		}
	}

	public var type: any Instantiatable {
		switch self {
		case .struct(let instance):
			instance.type
		case .protocol(let instance):
			instance.type
		case .enumType(let instance):
			instance.type
		}
	}
}

extension InstanceType: CustomStringConvertible {
	public var description: String {
		switch self {
		case .struct(let instance):
			instance.description
		case .protocol(let instance):
			instance.description
		case .enumType(let instance):
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
