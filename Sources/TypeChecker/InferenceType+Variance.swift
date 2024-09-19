//
//  InferenceType+Variance.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/18/24.
//

extension [InferenceType] {
	static func <= (lhs: [InferenceType], rhs: [InferenceType]) -> Bool {
		if lhs.count != rhs.count {
			return false
		}

		for (lhsElement, rhsElement) in zip(lhs, rhs) {
			if !(lhsElement <= rhsElement) {
				return false
			}
		}

		return true
	}
}

// Variance helpers
public extension InferenceType {
	static func <= (lhs: InferenceType, rhs: InferenceType) -> Bool {
		switch (lhs, rhs) {
		case let (.function(lhsParams, lhsReturns), .function(rhsParams, rhsReturns)):
			lhsParams <= rhsParams && lhsReturns <= rhsReturns
		case let (lhs as any Instantiatable, .instantiatable(.protocol(protocolType))):
			protocolType.missingConformanceRequirements(for: lhs, in: lhs.context).isEmpty
		case let (.instance(lhs), .instantiatable(.protocol(protocolType))):
			protocolType.missingConformanceRequirements(for: lhs.type, in: lhs.type.context).isEmpty
		case let (.enumCase(lhs), .instantiatable(.protocol(protocolType))):
			protocolType.missingConformanceRequirements(for: lhs.type, in: lhs.type.context).isEmpty
		default:
			lhs == rhs
		}
	}
}
