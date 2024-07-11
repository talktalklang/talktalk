//
//  ErrorSyntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct ErrorSyntax: Syntax, Expr, Decl {
	enum Expectation {
		case type(any Syntax.Type), token(Token.Kind)
	}

	var token: Token
	var expected: Expectation
	public var message: String

	public var position: Int { token.start }
	public var length: Int { token.length }

	public var description: String {
		"\(message): \(token), expected: \(expected)"
	}

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
