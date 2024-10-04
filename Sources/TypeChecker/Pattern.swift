//
//  Pattern.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/3/24.
//

public indirect enum Pattern: Equatable, CustomDebugStringConvertible {
	case variable(String, InferenceResult)
	case call(InferenceResult, [Pattern])

	public var debugDescription: String {
		switch self {
		case .variable(let string, let inferenceResult):
			"variable(\(string), \(inferenceResult.debugDescription))"
		case .call(let inferenceResult, let array):
			"call(\(inferenceResult.debugDescription), \(array.debugDescription))"
		}
	}
}
