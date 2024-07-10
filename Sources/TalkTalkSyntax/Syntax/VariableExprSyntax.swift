//
//  VariableExprSyntax.swift
//  
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct VariableExprSyntax: Syntax, Expr {
	public let position: Int
	public let length: Int
	public let name: IdentifierSyntax

	public var description: String {
		name.description
	}

	public var debugDescription: String {
		"""
		VariableExprSyntax(position: \(position), length: \(length))
			name: \(name.debugDescription)
		"""
	}
}
