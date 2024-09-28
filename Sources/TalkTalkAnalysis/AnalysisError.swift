//
//  AnalysisError.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import TalkTalkCore
import TypeChecker

public enum AnalyzerError: Error {
	case unexpectedCast(expected: String, received: String)
	case typeNotInferred(String)
	case symbolNotFound(String)
	case stdlibNotFound
}

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
	case typeCannotAssign(expected: InferenceType, received: InferenceType)
	case cannotReassignLet(variable: any Syntax)
	case invalidRedeclaration(variable: String, existing: Environment.Binding)
	case expressionCount(String)
	case matchNotExhaustive(String)
	case unexpectedType(expected: InferenceType, received: InferenceType, message: String)
	case conformanceError(name: String, type: InferenceType, conformances: [ProtocolType])
	case inferenceError(InferenceErrorKind)

	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .conformanceError(name, type, conformances):
			hasher.combine(name)
			hasher.combine(type)
			hasher.combine(conformances)
		case let .inferenceError(inferenceError):
			hasher.combine(inferenceError)
		case let .expressionCount(message):
			hasher.combine(message)
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
		case let .invalidRedeclaration(variable: name, existing: _):
			hasher.combine(name)
		case let .unexpectedType(expected: expected, received: received, message: message):
			hasher.combine(expected)
			hasher.combine(received)
			hasher.combine(message)
		case let .matchNotExhaustive(name):
			hasher.combine(name)
		}
	}
}

public struct AnalysisError: Hashable {
	public let kind: AnalysisErrorKind
	public let location: SourceLocation

	public func hash(into hasher: inout Hasher) {
		hasher.combine(kind)
	}

	public var description: String {
		"\(location.path): \(message) at ln \(location.line), col \(location.start.column)"
	}

	public var message: String {
		switch kind {
		case let .conformanceError(name, type, conformances):
			"Type does not conform to: \(conformances.map(\.name).joined(separator: ", ")). Missing: \(name) (\(type.debugDescription))"
		case let .inferenceError(inferenceError):
			inferenceError.description
		case let .argumentError(expected: a, received: b):
			if a == -1 {
				"Unable to determine expected arguments, probably because callee isn't callable."
			} else {
				"Expected \(a) arguments, got: \(b)"
			}
		case let .typeParameterError(expected: a, received: b):
			"Expected \(a) type parameters, got: \(b)"
		case let .typeNotFound(name):
			"Unknown type: \(name)"
		case let .unknownError(message):
			message
		case let .noMemberFound(receiver: receiver, property: property):
			"No property named `\(property)` for \(receiver)"
		case let .undefinedVariable(name):
			"Undefined variable `\(name)`"
		case let .typeCannotAssign(expected: expected, received: received):
			"Cannot assign \(received) to \(expected)"
		case let .cannotReassignLet(variable: syntax):
			"Cannot re-assign let variable: \(syntax.description)"
		case let .invalidRedeclaration(variable: name, existing: decl):
			"Cannot re-declare \(name). (defined as \(decl.location))."
		case let .matchNotExhaustive(message):
			message
		case let .unexpectedType(expected: _, received: _, message: message):
			message
		case let .expressionCount(message):
			message
		}
	}
}
