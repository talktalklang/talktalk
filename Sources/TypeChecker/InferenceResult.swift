//
//  InferenceResult.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

enum InferenceResult: Equatable, Hashable, CustomStringConvertible {
	case scheme(Scheme), type(InferenceType)

	var description: String {
		switch self {
		case .scheme(let scheme):
			"scheme(\(scheme))"
		case .type(let inferenceType):
			inferenceType.description
		}
	}

	var asType: InferenceType? {
		if case let .type(inferenceType) = self {
			return inferenceType
		}

		return nil
	}

	func asType(in context: InferenceContext) -> InferenceType {
		switch self {
		case .scheme(let scheme):
			context.instantiate(scheme: scheme)
		case .type(let inferenceType):
			inferenceType
		}
	}
}
