//
//  StructType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

public struct SerializedStructType: Codable {
	let name: String?
	var properties: [String: SerializedProperty]
	var methods: [String: SerializedProperty]
	var propertyOffsets: [String: Int]
	var methodOffsets: [String: Int]
}

public class StructType {
	public let name: String?
	public private(set) var properties: [String: Property]
	public private(set) var methods: [String: Property]
	public private(set) var propertyOffsets: [String: Int]
	public private(set) var methodOffsets: [String: Int]

	public init(name: String? = nil, properties: [String: Property], methods: [String: Property]) {
		self.name = name
		self.properties = properties
		self.methods = methods
		self.propertyOffsets = [:]
		self.methodOffsets = [:]
	}

	public func offset(for propertyName: String) -> Int {
		propertyOffsets[propertyName]!
	}

	public func offset(method propertyName: String) -> Int {
		methodOffsets[propertyName]!
	}

	public func add(property: Property) {
		propertyOffsets[property.name] = properties.count
		properties[property.name] = property
	}

	public func add(method property: Property) {
		if methodOffsets[property.name] == nil {
			methodOffsets[property.name] = methods.count
		}

		methods[property.name] = property
	}
}
