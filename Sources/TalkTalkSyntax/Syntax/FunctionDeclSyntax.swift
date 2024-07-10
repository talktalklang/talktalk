//
//  FunctionDeclSyntax.swift
//
//
//  Created by Pat Nakajima on 7/9/24.
//
public struct FunctionDeclSyntax: Syntax, Decl {
	public var position: Int
	public var length: Int
	public var name: IdentifierSyntax
	public var parameters: ParameterListSyntax
	public var body: BlockStmtSyntax

	public var description: String {
		"""
		func \(name.description)(\(parameters.description)) \(body.description)
		"""
	}

	public var debugDescription: String {
		"""
		FunctionDeclSyntax(position: \(position), length: \(length))
			name: \(name.debugDescription)
			parameters:
				\(parameters.debugDescription)
			body:
				\(body.debugDescription)
		"""
	}
}
