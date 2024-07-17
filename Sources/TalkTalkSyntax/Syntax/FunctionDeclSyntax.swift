//
//  FunctionDeclSyntax.swift
//
//
//  Created by Pat Nakajima on 7/9/24.
//
public struct FunctionDeclSyntax: Syntax, Decl {
	public let start: Token
	public let end: Token
	public var name: IdentifierSyntax
	public var parameters: ParameterListSyntax
	public var typeDecl: TypeDeclSyntax?
	public var body: BlockStmtSyntax

	public func accept<Visitor: ASTVisitor>(
		_ visitor: Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
