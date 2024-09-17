//
//  LexicalScope.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import OrderedCollections
import TalkTalkSyntax
import TypeChecker

public protocol LexicalScopeType {
	var name: String { get }
	var methods: OrderedDictionary<String, Method> { get }
	var properties: OrderedDictionary<String, Property> { get }
}

public class LexicalScope {
	public var type: any LexicalScopeType

	init(type: any LexicalScopeType) {
		self.type = type
	}

	var methods: OrderedDictionary<String, Method> {
		type.methods
	}

	var properties: OrderedDictionary<String, Property> {
		type.properties
	}
}
