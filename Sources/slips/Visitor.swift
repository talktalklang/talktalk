//
//  Visitor.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol Visitor {
	associatedtype Value

	func visit(_ expr: CallExpr) -> Value
	func visit(_ expr: DefExpr) -> Value
	func visit(_ expr: ErrorExpr) -> Value
	func visit(_ expr: LiteralExpr) -> Value
	func visit(_ expr: VarExpr) -> Value
	func visit(_ expr: AddExpr) -> Value
	func visit(_ expr: IfExpr) -> Value
}
