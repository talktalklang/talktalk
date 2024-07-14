//
//  ErrorSyntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct ErrorSyntax: Syntax, Expr, Decl {
	enum Expectation {
		case type(any Syntax.Type), token(Token.Kind), none
	}

	var token: Token
	var expected: Expectation
	public var message: String

	public var start: Token { token }
	public var end: Token { token }

	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
	}

	public var description: String {
		"\(message): \(token), expected: \(expected)"
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
