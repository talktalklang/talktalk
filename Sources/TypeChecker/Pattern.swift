//
//  Pattern.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/3/24.
//

public indirect enum Pattern: Equatable, CustomDebugStringConvertible {
	case variable(String, InferenceResult)
	case call(InferenceResult, [Pattern])
	case value(InferenceType)

	public var debugDescription: String {
		switch self {
		case .variable(let string, let inferenceResult):
			"Pattern variable(\(string), \(inferenceResult.debugDescription))"
		case .call(let inferenceResult, let array):
			"Pattern call(\(inferenceResult.debugDescription), \(array.debugDescription))"
		case .value(let inferenceType):
			"Pattern value(\(inferenceType.debugDescription))"
		}
	}
}
