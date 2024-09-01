//
//  InferenceType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/1/24.
//

import TypeChecker

extension InferenceType {
	func assignable(from other: InferenceType) -> Bool {
		switch (self, other) {
		case let (.base(lhs), .base(rhs)):
			return lhs == rhs
		default:
			return false
		}
	}
}
