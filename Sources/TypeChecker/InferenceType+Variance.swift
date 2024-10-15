//
//  InferenceType+Variance.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/18/24.
//

extension [InferenceResult] {
	func covariant(with rhs: [InferenceResult], in context: Context) -> Bool {
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
extension InferenceType {
	func covariant(with rhs: InferenceType, in context: Context) -> Bool {
		switch (self, rhs) {
		case let (.function(lhsParams, lhsReturns), .function(rhsParams, rhsReturns)):
			return lhsParams.covariant(with: rhsParams, in: context) && lhsReturns.covariant(with: rhsReturns, in: context)
		case let (lhs as any MemberOwner, .type(.protocol(protocolType))):
			return protocolType.missingConformanceRequirements(for: lhs, in: context).isEmpty
		case let (.instance(lhs), .instance(.protocol(rhs))):
			return rhs.type.missingConformanceRequirements(for: lhs.type, in: context).isEmpty
		case let (.typeVar, t), let (t, .typeVar):
			context.addConstraint(
				Constraints.Equality(context: context, lhs: .resolved(self), rhs: .resolved(t), location: [.synthetic(.less)])
			)

			return true
		default:
			return self == rhs
		}
	}
}
