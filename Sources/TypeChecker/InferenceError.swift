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
	case memberNotFound(StructType, String)
	case missingConstraint(InferenceType)
	case subscriptNotAllowed(InferenceType)
	case unificationError(InferenceType, InferenceType)
	case invalidRedeclaration(String)

	public var description: String {
		switch self {
		case .invalidRedeclaration(let name):
			"Variable already declared: \(name)"
		case .unificationError(let a, let b):
			"Cannot unify \(a) and \(b)"
		case .undefinedVariable(let string):
			"Undefined variable: \(string)"
		case .unknownError(let string):
			string
		case .constraintError(let string):
			"Unresolved constraint: \(string)"
		case .argumentError(let expected, let actual):
			"Expected \(expected) args, got \(actual)"
		case .typeError(let string):
			string
		case .memberNotFound(let structType, let string):
			"\(structType) has no member `\(string)`"
		case .missingConstraint(let inferenceType):
			"Constraint missing: \(inferenceType)"
		case .subscriptNotAllowed(let inferenceType):
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
