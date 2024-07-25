//
//  Visitor.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol Visitor {
	associatedtype Value

	func visit(_ expr: CallExpr, _ scope: Scope) -> Value
	func visit(_ expr: DefExpr, _ scope: Scope) -> Value
	func visit(_ expr: ErrorExpr, _ scope: Scope) -> Value
	func visit(_ expr: LiteralExpr, _ scope: Scope) -> Value
	func visit(_ expr: VarExpr, _ scope: Scope) -> Value
	func visit(_ expr: AddExpr, _ scope: Scope) -> Value
	func visit(_ expr: IfExpr, _ scope: Scope) -> Value
	func visit(_ expr: FuncExpr, _ scope: Scope) -> Value
	func visit(_ expr: ParamsExpr, _ scope: Scope) -> Value
}
