//
//  MemberOwner.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/2/24.
//

import OrderedCollections

public protocol MemberOwner: CustomDebugStringConvertible {
	var name: String { get }
	var members: [String: InferenceResult] { get }
	var typeParameters: OrderedDictionary<String, TypeVariable> { get set }

	func staticMember(named name: String) -> InferenceResult?
	func member(named name: String) -> InferenceResult?
	func add(member: InferenceResult, named name: String, isStatic: Bool) throws
}

extension MemberOwner {
	func equals(_ rhs: any MemberOwner) -> Bool {
		name == rhs.name
	}

	var wrapped: TypeWrapper {
		switch self {
		case let type as StructType:
			return .struct(type)
		case let type as Enum:
			return .enum(type)
		case let type as Enum.Case:
			return .enumCase(type)
		default:
			fatalError("Unexpected type: \(self)")
		}
	}
}
