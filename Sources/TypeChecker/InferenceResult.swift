//
//  InferenceResult.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

enum InferenceResult: Equatable, Hashable {
	case scheme(Scheme), type(InferenceType)

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
