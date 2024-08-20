//
//  SyntaxError.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

public enum SyntaxErrorKind: Equatable {
	case lexerError(String),
	     unexpectedToken(expected: Token.Kind, got: Token),
	     infiniteLoop,
			 cannotAssign
}

public struct SyntaxError: Equatable, @unchecked Sendable {
	public static func == (lhs: SyntaxError, rhs: SyntaxError) -> Bool {
		lhs.line == rhs.line && lhs.column == rhs.column && lhs.kind == rhs.kind
	}

	public let line: Int
	public let column: Int
	public let kind: SyntaxErrorKind
	public let syntax: (any Syntax)?

	init(line: Int, column: Int, kind: SyntaxErrorKind, syntax: (any Syntax)? = nil) {
		self.line = line
		self.column = column
		self.kind = kind
		self.syntax = syntax
	}
}
