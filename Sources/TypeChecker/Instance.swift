//
//  Instance.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/2/24.
//

public enum InstanceWrapper {
	case `struct`(Instance<StructType>)

	var substitutions: [TypeVariable: InferenceResult] {
		get {
			switch self {
			case .struct(let instance):
				instance.substitutions
			}
		}

		set {
			switch self {
			case .struct(let instance):
				instance.substitutions = newValue
			}
		}
	}

	func member(named name: String) -> InferenceResult? {
		switch self {
		case .struct(let instance):
			instance.member(named: name)
		}
	}

	func instance<T: Instantiatable & MemberOwner>(ofType: T.Type) -> Instance<T>? {
		switch self {
		case .struct(let instance):
			if let instance = instance as? Instance<T> {
				return instance
			}
		}

		return nil
	}

	var type: any Instantiatable {
		switch self {
		case .struct(let instance):
			return instance.type
		}
	}
}

public class Instance<Kind: Instantiatable & MemberOwner> {
	public var type: Kind
	public var substitutions: [TypeVariable: InferenceResult]
	public var name: String { type.name }

	init(type: Kind, substitutions: [TypeVariable : InferenceResult] = [:]) {
		self.type = type
		self.substitutions = substitutions
	}

	static func extract(from type: InferenceType) -> Instance<Kind>? {
		guard case let .instance(wrapper) = type else {
			return nil
		}

		return wrapper.instance(ofType: Kind.self)
	}

	public var wrapped: InstanceWrapper {
		switch self {
		case let instance as Instance<StructType>:
			.struct(instance)
		default:
			fatalError("Unexpected InstanceWrapper: \(self)")
		}
	}

	public func member(named name: String) -> InferenceResult? {
		type.member(named: name)
	}

	public func staticMember(named name: String) -> InferenceResult? {
		nil
	}

	public func add(member: InferenceResult, named name: String, isStatic: Bool) throws {}
}
