//
//  ArgumentListSyntax.swift
//
//
//  Created by Pat Nakajima on 7/9/24.
//
public struct ArgumentListSyntax: Syntax {
	public let start: Token
	public let end: Token
	public let arguments: [any Expr]

	public subscript(_ index: Int) -> any Expr {
		return arguments[index]
	}

	public var count: Int {
		arguments.count
	}

	public var isEmpty: Bool {
		arguments.isEmpty
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: inout Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: &context)
	}
}
