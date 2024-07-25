//
//  Expr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol Expr: CustomStringConvertible {
	func accept<V: Visitor>(_ visitor: V, _ scope: Scope) -> V.Value
}

public extension Expr {
	func cast<T: Expr>(_: T.Type) -> T {
		self as! T
	}

	var description: String {
		accept(Formatter(), Scope())
	}
}
