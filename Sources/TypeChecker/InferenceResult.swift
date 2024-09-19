//
//  InferenceResult.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

public enum InferenceResult: Equatable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
	case scheme(Scheme), type(InferenceType)

	public var description: String {
		switch self {
		case let .scheme(scheme):
			"scheme(\(scheme))"
		case let .type(inferenceType):
			inferenceType.description
		}
	}

	public var debugDescription: String {
		switch self {
		case let .scheme(scheme):
			"scheme(\(scheme.debugDescription))"
		case let .type(inferenceType):
			inferenceType.debugDescription
		}
	}

	var asType: InferenceType? {
		if case let .type(inferenceType) = self {
			return inferenceType
		}

		return nil
	}

	public func asType(in context: InferenceContext) -> InferenceType {
		switch self {
		case let .scheme(scheme):
			context.instantiate(scheme: scheme)
		case let .type(inferenceType):
			inferenceType
		}
	}
}
