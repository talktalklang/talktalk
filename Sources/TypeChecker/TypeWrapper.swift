//
//  TypeWrapper.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/5/24.
//

import OrderedCollections

public enum TypeWrapper: MemberOwner {
	case `struct`(StructType), `enum`(Enum), enumCase(Enum.Case), `protocol`(ProtocolType)

	public var module: String {
		switch self {
		case .struct(let structType):
			structType.module
		case .enum(let `enum`):
			`enum`.module
		case .enumCase(let `case`):
			`case`.module
		case .protocol(let protocolType):
			protocolType.module
		}
	}

	public var members: [String : InferenceResult] {
		switch self {
		case .struct(let structType):
			structType.members
		case .enum(let `enum`):
			`enum`.members
		case .enumCase(let `case`):
			`case`.members
		case .protocol(let protocolType):
			protocolType.members
		}
	}

	public var debugDescription: String {
		switch self {
		case .struct(let structType):
			structType.debugDescription
		case .enum(let `enum`):
			`enum`.debugDescription
		case .enumCase(let `case`):
			`case`.debugDescription
		case .protocol(let protocolType):
			protocolType.debugDescription
		}
	}

	public var name: String {
		switch self {
		case .struct(let type):
			type.name
		case .enum(let type):
			type.name
		case .enumCase(let type):
			type.name
		case .protocol(let type):
			type.name
		}
	}

	public var typeParameters: OrderedDictionary<String, TypeVariable> {
		get {
			switch self {
			case .struct(let type):
				type.typeParameters
			case .enum(let type):
				type.typeParameters
			case .enumCase(let type):
				type.typeParameters
			case .protocol(let type):
				type.typeParameters
			}
		}

		set {
			fatalError("Type parameters must be set on wrapped types directly")
		}
	}

	func instantiate(with variables: Substitutions) -> InstanceWrapper {
		switch self {
		case .struct(let type):
			return .struct(type.instantiate(with: variables))
		case .enum(let type):
			return .enum(type.instantiate(with: variables))
		case .enumCase(let type):
			return .enumCase(type.instantiate(with: variables))
		case .protocol(let type):
			return .protocol(type.instantiate(with: variables))
		}
	}

	public func staticMember(named name: String) -> InferenceResult? {
		switch self {
		case .struct(let type):
			type.staticMember(named: name)
		case .enum(let type):
			type.staticMember(named: name)
		case .enumCase(let type):
			type.staticMember(named: name)
		case .protocol(let type):
			type.staticMember(named: name)
		}
	}

	public func member(named name: String) -> InferenceResult? {
		switch self {
		case .struct(let type):
			type.member(named: name)
		case .enum(let type):
			type.member(named: name)
		case .enumCase(let type):
			type.member(named: name)
		case .protocol(let type):
			type.member(named: name)
		}
	}

	public func add(member: InferenceResult, named name: String, isStatic: Bool) throws {
		fatalError("Members must be added on concrete wrapped types")
	}
}
