//
//  TypeDeclaration.swift
//
//
//  Created by Pat Nakajima on 7/20/24.
//

import TalkTalkSyntax

public struct TypeDeclaration: Declaration {
	public var syntax: any Syntax
	public var type: any SemanticType
	public var scope: Scope

	public func accept<V: ABTVisitor>(_ visitor: V) -> V.Value {
		visitor.visit(self)
	}
}
