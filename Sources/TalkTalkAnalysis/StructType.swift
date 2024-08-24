//
//  StructType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode

public struct SerializedStructType: Codable {
	let name: String?
	var properties: [String: SerializedProperty]
	var methods: [String: SerializedMethod]
	var initializers: [String: SerializedMethod]
	var propertyOffsets: [String: Int]
	var methodOffsets: [String: Int]
}

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

	func placeholderGenericTypes() -> [String: TypeID] {
		typeParameters.reduce(into: [:]) { res, param in
			res[param.name] = TypeID(.placeholder)
		}
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
