//
//  AnalyzedErrorExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedErrorExpr: AnalyzedExpr, ErrorExpr {
	public var type: ValueType
	public var message: String

	public init(type: ValueType, message: String) {
		self.type = type
		self.message = message
		print(message)
	}

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) -> V.Value {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}
