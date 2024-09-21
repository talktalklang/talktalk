//
//  InferenceType+Variance.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/18/24.
//

extension [InferenceType] {
	func covariant(with rhs: [InferenceType], in context: InferenceContext) -> Bool {
		if count != rhs.count {
			return false
		}

		for (lhsElement, rhsElement) in zip(self, rhs) {
			if !(lhsElement.covariant(with: rhsElement, in: context)) {
				return false
			}
		}

		return true
	}
}

// Variance helpers
public extension InferenceType {
	func covariant(with rhs: InferenceType, in context: InferenceContext) -> Bool {
		switch (self, rhs) {
		case let (.function(lhsParams, lhsReturns), .function(rhsParams, rhsReturns)):
			return lhsParams.covariant(with: rhsParams, in: context) && lhsReturns.covariant(with: rhsReturns, in: context)
		case let (lhs as any Instantiatable, .instantiatable(.protocol(protocolType))):
			return protocolType.missingConformanceRequirements(for: lhs, in: lhs.context).isEmpty
		case let (.instance(lhs), .instance(.protocol(rhs))):
			return rhs.type.missingConformanceRequirements(for: lhs.type, in: lhs.type.context).isEmpty
		case let (.instance(lhs), .instantiatable(.protocol(protocolType))):
			return protocolType.missingConformanceRequirements(for: lhs.type, in: lhs.type.context).isEmpty
		case let (.enumCase(lhs), .instantiatable(.protocol(protocolType))):
			return protocolType.missingConformanceRequirements(for: lhs.type, in: lhs.type.context).isEmpty
		case let (.typeVar, rhs):
			context.addConstraint(.equality(self, rhs, at: [.synthetic(.less)]))

			return true
		default:
			return self == rhs
		}
	}
}
