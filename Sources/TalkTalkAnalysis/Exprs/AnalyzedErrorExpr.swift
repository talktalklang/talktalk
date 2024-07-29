//
//  AnalyzedErrorExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedErrorExpr: AnalyzedExpr, ErrorExpr {
	public var type: ValueType
	let expr: any ErrorExpr

	public var message: String { expr.message }
	public var location: SourceLocation { expr.location }

	public init(type: ValueType, expr: any ErrorExpr) {
		self.type = type
		self.expr = expr
		print(message)
	}

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}
