//
//  AnalyzedSyntax.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public protocol AnalyzedSyntax: Syntax {
	var typeID: TypeID { get }
	var analyzedChildren: [any AnalyzedSyntax] { get }

	func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor
}

public extension AnalyzedSyntax {
	var typeAnalyzed: ValueType {
		typeID.registry.lookup(typeID)
	}
}
