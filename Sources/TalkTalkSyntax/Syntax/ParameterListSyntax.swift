//
//  ParameterListSyntax.swift
//
//
//  Created by Pat Nakajima on 7/9/24.
//
public struct ParameterListSyntax: Syntax {
	public let start: Token
	public let end: Token
	public let parameters: [IdentifierSyntax]

	public subscript(_ index: Int) -> IdentifierSyntax {
		return parameters[index]
	}

	public var count: Int {
		parameters.count
	}

	public var isEmpty: Bool {
		parameters.isEmpty
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: inout Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: &context)
	}
}
