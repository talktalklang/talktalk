//
//  AnalysisStructType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import OrderedCollections
import TalkTalkBytecode
import TalkTalkSyntax

public class AnalysisStructType {
	public let id: SyntaxID
	public let name: String?
	public private(set) var properties: OrderedDictionary<String, Property>
	public private(set) var methods: OrderedDictionary<String, Method>
	public var typeParameters: [TypeParameter]

	public init(
		id: SyntaxID,
		name: String? = nil,
		properties: OrderedDictionary<String, Property>,
		methods: OrderedDictionary<String, Method>,
		typeParameters: [TypeParameter]
	) {
		self.id = id
		self.name = name
		self.properties = properties
		self.methods = methods
		self.typeParameters = typeParameters
	}

	public func add(property: Property) {
		properties[property.name] = property
	}

	public func add(method: Method) {
		methods[method.name] = method
	}

	public func add(initializer method: Method) {
		methods[method.name] = method
	}
}
