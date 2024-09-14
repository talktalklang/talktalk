//
//  InferencerError.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/3/24.
//

import Foundation

public enum InferencerError: Error, CustomStringConvertible, LocalizedError {
	case typeNotInferred(String)
	case cannotInfer(String)
	case parametersNotAvailable(String)

	public var errorDescription: String? {
		description
	}

	public var description: String {
		switch self {
		case let .typeNotInferred(string):
			"Type not inferred for \(string.debugDescription)"
		case let .cannotInfer(string):
			"Type cannot be inferred for \(string.debugDescription)"
		case let .parametersNotAvailable(string):
			"Parameters not available for \(string)"
		}
	}
}
