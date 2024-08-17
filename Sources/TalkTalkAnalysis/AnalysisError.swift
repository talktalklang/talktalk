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
	case undefinedVariable(String)
	case typeCannotAssign(expected: TypeID, received: TypeID)
	case cannotReassignLet(variable: any AnalyzedExpr)

	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .argumentError(expected, received):
			hasher.combine([expected, received])
		case let .typeParameterError(expected, received):
			hasher.combine([expected, received])
		case let .noMemberFound(receiver, property):
			hasher.combine(receiver.description)
			hasher.combine(property)
		case let .typeNotFound(string):
			hasher.combine(string)
		case let .unknownError(string):
			hasher.combine(string)
		case let .undefinedVariable(string):
			hasher.combine(string)
		case let .typeCannotAssign(expected, received):
			hasher.combine(expected)
			hasher.combine(received)
		case let .cannotReassignLet(variable: syntax):
			hasher.combine(syntax.description.hashValue)
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
