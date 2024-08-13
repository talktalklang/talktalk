//
//  AnalyzedErrorExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedErrorSyntax: AnalyzedExpr, ErrorSyntax {
	public let typeID: TypeID
	let expr: any ErrorSyntax
	public var analyzedChildren: [any AnalyzedSyntax] { [] }
	public let environment: Environment

	public var message: String { expr.message }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }
	public var expectation: ParseExpectation { expr.expectation }

	public init(typeID: TypeID, expr: any ErrorSyntax, environment: Environment) {
		self.typeID = typeID
		self.expr = expr
		self.environment = environment
	}

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
