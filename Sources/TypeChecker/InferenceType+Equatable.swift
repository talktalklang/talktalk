//
//  InferenceType+Equatable.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/18/24.
//

extension InferenceType: Equatable {
	public static func == (lhs: InferenceType, rhs: InferenceType) -> Bool {
		switch (lhs, rhs) {
		case let (.self(lhs), .self(rhs)):
			lhs.equals(rhs)
		case let (.type(.struct(lhs)), .type(.struct(rhs))):
			lhs == rhs
		case let (.instance(lhs), .instance(rhs)):
			lhs.type.name == rhs.type.name
		case let (.function(lhsParams, lhsReturns), .function(rhsParams, rhsReturns)):
			lhsParams == rhsParams && lhsReturns == rhsReturns
		case let (.typeVar(lhs), .typeVar(rhs)):
			lhs == rhs
		case let (.base(lhs), .base(rhs)):
			lhs == rhs
		case let (.instanceV1(lhs), .instanceV1(rhs)):
			lhs.equals(rhs)
		case let (.instantiatable(lhs), .instantiatable(rhs)):
			lhs == rhs
		case let (.placeholder(lhs), .placeholder(rhs)):
			lhs == rhs
		case let (.error(lhs), .error(rhs)):
			lhs == rhs
		case let (.kind(lhs), .kind(rhs)):
			lhs == rhs
		case let (.selfVar(lhs), .selfVar(rhs)):
			lhs == rhs
		case let (.enumCaseV1(lhs), .enumCaseV1(rhs)):
			lhs == rhs
		case let (.pattern(lhs), .pattern(rhs)):
			lhs == rhs
		case (.any, .any):
			true
		case (.void, .void):
			true
		default:
			false
		}
	}
}
