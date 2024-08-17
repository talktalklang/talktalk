//
//  AnalyzedErrorExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedErrorSyntax: AnalyzedExpr, ParseError, Member {
	public var expr: any TalkTalkSyntax.Syntax { wrapped }

	public var slot: Int = -1
	public var name: String = ""
	public var isMutable: Bool = false

	public let typeID: TypeID
	public let wrapped: any ParseError
	public var analyzedChildren: [any AnalyzedSyntax] { [] }
	public let environment: Environment

	public var message: String { wrapped.message }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }
	public var expectation: ParseExpectation { wrapped.expectation }

	public init(typeID: TypeID, expr: any ParseError, environment: Environment) {
		self.typeID = typeID
		self.wrapped = expr
		self.environment = environment
	}

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
