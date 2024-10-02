//
//  InferenceType+Members.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/2/24.
//

extension InferenceType {
	func member(named name: String) -> InferenceResult? {
		switch self {
		case let .instance(instance):
			return instance.member(named: name)
		default:
			return nil
		}
	}
}
