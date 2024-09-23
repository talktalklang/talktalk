//
//  InferenceError.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/1/24.
//

import TalkTalkSyntax

public enum InferenceErrorKind: Equatable, Hashable, CustomStringConvertible {
	case undefinedVariable(String)
	case unknownError(String)
	case constraintError(String)
	case argumentError(expected: Int, actual: Int)
	case typeError(String)
	case memberNotFound(InferenceType, String)
	case missingConstraint(InferenceType)
	case subscriptNotAllowed(InferenceType)
	case unificationError(InferenceType, InferenceType)
	case invalidRedeclaration(String)
	case diagnosticError(Diagnostic)

	public var description: String {
		switch self {
		case let .diagnosticError(diagnostic):
			diagnostic.message
		case let .invalidRedeclaration(name):
			"Variable already declared: \(name)"
		case let .unificationError(a, b):
			"Cannot unify \(a) and \(b)"
		case let .undefinedVariable(string):
			"Undefined variable: \(string)"
		case let .unknownError(string):
			string.description
		case let .constraintError(string):
			"Unresolved constraint: \(string)"
		case let .argumentError(expected, actual):
			"Expected \(expected) args, got \(actual)"
		case let .typeError(string):
			string.description
		case let .memberNotFound(type, string):
			"\(type) has no member `\(string)`"
		case let .missingConstraint(inferenceType):
			"Constraint missing: \(inferenceType)"
		case let .subscriptNotAllowed(inferenceType):
			"Subscript not implemented for \(inferenceType)"
		}
	}
}

public struct InferenceError: Hashable, Equatable, CustomStringConvertible {
	public let kind: InferenceErrorKind
	public let location: SourceLocation

	public init(kind: InferenceErrorKind, location: SourceLocation) {
		self.kind = kind
		self.location = location
	}

	public var description: String {
		kind.description + " at \(location)"
	}
}
