//
//  InferenceType+Equatable.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/18/24.
//

extension InferenceType: Equatable {
	public static func ==(lhs: InferenceType, rhs: InferenceType) -> Bool {
		switch (lhs, rhs) {
		case let (.function(lhsParams, lhsReturns), .function(rhsParams, rhsReturns)):
			return lhsParams == rhsParams && lhsReturns == rhsReturns
		case let (.typeVar(lhs), .typeVar(rhs)):
			return lhs == rhs
		case let (.base(lhs), .base(rhs)):
			return lhs == rhs
		case let (.instance(lhs), .instance(rhs)):
			return lhs == rhs
		case let (.instantiatable(lhs), .instantiatable(rhs)):
			return lhs.hashValue == rhs.hashValue
		case let (.placeholder(lhs), .placeholder(rhs)):
			return lhs == rhs
		case let (.error(lhs), .error(rhs)):
			return lhs == rhs
		case let (.kind(lhs), .kind(rhs)):
			return lhs == rhs
		case let (.selfVar(lhs), .selfVar(rhs)):
			return lhs == rhs
		case let (.enumCase(lhs), .enumCase(rhs)):
			return lhs == rhs
		case let (.pattern(lhs), .pattern(rhs)):
			return lhs == rhs
		case (.any, .any):
			return true
		case (.void, .void):
			return true
		default:
			return false
		}
	}
}
