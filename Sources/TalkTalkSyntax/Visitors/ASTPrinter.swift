//
//  ASTPrinter.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public struct ASTPrinter: Visitor {
	public struct Context {}
	public typealias Value = String

	func dump(_ expr: any Expr) -> String {
		""
	}

	public func visit(_ expr: any CallExpr, _ context: Context) -> String {
		""
	}
	
	public func visit(_ expr: any DefExpr, _ context: Context) -> String {
		""
	}
	
	public func visit(_ expr: any ErrorExpr, _ context: Context) -> String {
		""
	}
	
	public func visit(_ expr: any LiteralExpr, _ context: Context) -> String {
		""
	}
	
	public func visit(_ expr: any VarExpr, _ context: Context) -> String {
		""
	}
	
	public func visit(_ expr: any BinaryExpr, _ context: Context) -> String {
		""
	}
	
	public func visit(_ expr: any IfExpr, _ context: Context) -> String {
		""
	}
	
	public func visit(_ expr: any WhileExpr, _ context: Context) -> String {
		""
	}
	
	public func visit(_ expr: any BlockExpr, _ context: Context) -> String {
		""
	}
	
	public func visit(_ expr: any FuncExpr, _ context: Context) -> String {
		""
	}
	
	public func visit(_ expr: any ParamsExpr, _ context: Context) -> String {
		""
	}
	
	public func visit(_ expr: any Param, _ context: Context) -> String {
		""
	}
}
