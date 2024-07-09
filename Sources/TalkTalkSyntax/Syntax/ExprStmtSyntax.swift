//
//  Untitled.swift
//  
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct ExprStmtSyntax: Syntax {
	public let position: Int
	public let length: Int
	public let expr: any Expr
}
