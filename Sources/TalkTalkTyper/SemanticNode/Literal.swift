//
//  Literal.swift
//
//
//  Created by Pat Nakajima on 7/20/24.
//

import TalkTalkSyntax

public struct Literal: SemanticNode, Expression {
	public var syntax: any Syntax
	public var scope: Scope
	public var type: any SemanticType

	public var value: any Value {
		switch syntax {
		case let syntax as IntLiteralSyntax:
			Int(syntax.lexeme)!
		default:
			false
		}
	}

	public func accept<V: ABTVisitor>(_ visitor: V) -> V.Value {
		visitor.visit(self)
	}
}
