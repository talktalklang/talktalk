//
//  AnalysisEnum.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/16/24.
//

import OrderedCollections

public class AnalysisEnum: LexicalScopeType {
	public let name: String
	public var methods: OrderedDictionary<String, Method>

	public init(
		name: String,
		methods: OrderedDictionary<String, Method>
	) {
		self.name = name
		self.methods = methods
	}

	public var properties: OrderedDictionary<String, Property> { [:] }

	public func add(method: Method) {
		methods[method.name] = method
	}
}
