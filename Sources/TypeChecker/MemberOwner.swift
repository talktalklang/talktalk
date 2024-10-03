//
//  MemberOwner.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/2/24.
//

public protocol MemberOwner {
	var name: String { get }
	var typeParameters: [String: TypeVariable] { get }

	func staticMember(named name: String) -> InferenceResult?
	func member(named name: String) -> InferenceResult?
	func add(member: InferenceResult, named name: String, isStatic: Bool) throws
}

extension MemberOwner {
	func equals(_ rhs: any MemberOwner) -> Bool {
		name == rhs.name
	}
}
