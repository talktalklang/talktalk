//
//  FormatterVisitor+Context.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/14/24.
//

extension FormatterVisitor {
	struct Context {
		enum ChildTrait: Hashable {
			case hasFunc
		}

		enum Kind {
			case declBlock, stmtBlock, topLevel
		}

		var kind: Kind
		var lastNode: (any Syntax)?
		var childTraits = TraitCollection<ChildTrait>()

		var allowsSingleLineStmtBlock: Bool {
			kind != .declBlock
		}

		func copy() -> Context {
			var copy = self
			copy.childTraits = childTraits.copy()
			return copy
		}

		func `in`(_ kind: Kind) -> Context {
			var copy = self
			copy.kind = kind
			copy.childTraits = childTraits.copy()
			return copy
		}

		func last(_ syntax: (any Syntax)?) -> Context {
			var copy = self
			copy.lastNode = syntax
			return copy
		}
	}
}
