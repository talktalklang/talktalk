//
//  AnalyzedExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public protocol AnalyzedExpr: Expr, AnalyzedSyntax {
	var type: ValueType { get set }
	var analyzedChildren: [any AnalyzedSyntax] { get }
	var environment: Environment { get }

	func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor
}
