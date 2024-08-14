//
//  AnalysisError.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import TalkTalkSyntax

public enum AnalysisErrorKind: Hashable {
	public static func == (lhs: AnalysisErrorKind, rhs: AnalysisErrorKind) -> Bool {
		lhs.hashValue == rhs.hashValue
	}
	
	case argumentError(expected: Int, received: Int)
	case typeParameterError(expected: Int, received: Int)
	case noMemberFound(receiver: any Syntax, property: String)
	case typeNotFound(String)
	case unknownError(String)

	public func hash(into hasher: inout Hasher) {
		switch self {
		case .argumentError(let expected, let received):
			hasher.combine([expected, received])
		case .typeParameterError(let expected, let received):
			hasher.combine([expected, received])
		case .noMemberFound(let receiver, let property):
			hasher.combine(receiver.description)
			hasher.combine(property)
		case .typeNotFound(let string):
			hasher.combine(string)
		case .unknownError(let string):
			hasher.combine(string)
		}
	}
}

public struct AnalysisError: Hashable {
	public let kind: AnalysisErrorKind
	public let location: SourceLocation

	public func hash(into hasher: inout Hasher) {
		hasher.combine(kind)
	}
}
