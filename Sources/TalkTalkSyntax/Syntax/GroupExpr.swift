//
//  GroupExpr.swift
//
//
//  Created by Pat Nakajima on 7/9/24.
//
public struct GroupExpr: Expr, Syntax {
	public let position: Int
	public let length: Int
	public let expr: any Expr

	public var description: String {
		"(\(expr.description))"
	}
}
