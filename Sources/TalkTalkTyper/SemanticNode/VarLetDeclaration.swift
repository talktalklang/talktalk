//
//  VarLetDeclaration.swift
//
//
//  Created by Pat Nakajima on 7/20/24.
//

import TalkTalkSyntax

public struct VarLetDeclaration: Declaration {
	public var type: any SemanticType
	public var syntax: any Syntax
	public var scope: Scope
	public var name: String
	public var expression: (any Expression)?

	// If a variable is used as a return then we can try to update
	// it using return type info we might have
	public var isUsedAsReturn: Bool = false

	public func accept<V: ABTVisitor>(_ visitor: V) -> V.Value {
		visitor.visit(self)
	}
}
