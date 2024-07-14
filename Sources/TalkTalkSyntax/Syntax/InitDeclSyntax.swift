//
//  InitDeclSyntax.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
public struct InitDeclSyntax: Decl, Syntax {
	public let start: Token
	public let end: Token

	public var parameters: ParameterListSyntax
	public var body: BlockStmtSyntax

	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		for parameter in parameters.parameters {
			hasher.combine(parameter)
		}
		for decl in body.decls {
			hasher.combine(decl)
		}
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
