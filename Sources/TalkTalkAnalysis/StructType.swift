//
//  StructType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode

public class StructType {
	public let name: String?
	public private(set) var properties: [String: Property]
	public private(set) var methods: [String: Method]
	public var typeParameters: [TypeParameter]

	public init(
		name: String? = nil,
		properties: [String: Property],
		methods: [String: Method],
		typeParameters: [TypeParameter]
	) {
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
