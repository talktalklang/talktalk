//
//  InferencerError.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/3/24.
//

public enum InferencerError: Error, CustomStringConvertible {
	case typeNotInferred(String)
	case cannotInfer(String)
	case parametersNotAvailable(String)

	public var description: String {
		switch self {
		case .typeNotInferred(let string):
			"Type not inferred for \(string.debugDescription)"
		case .cannotInfer(let string):
			"Type cannot be inferred for \(string.debugDescription)"
		case .parametersNotAvailable(let string):
			"Parameters not available for \(string)"
		}
	}
}
