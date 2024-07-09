//
//  GroupingSyntax.swift
//  
//
//  Created by Pat Nakajima on 7/8/24.
//
struct GroupingSyntax: Syntax, Expr {
	let position: Int
	let length: Int
	let expression: any Expr
}
