//
//  Scheme.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

public struct Scheme: Equatable, CustomStringConvertible, CustomDebugStringConvertible, Hashable {
	public let name: String?
	let variables: [TypeVariable]
	let type: InferenceType
	let substitutions: [TypeVariable: InferenceType]

	init(name: String?, variables: [TypeVariable], type: InferenceType, substitutions: [TypeVariable : InferenceType] = [:]) {
		self.name = name
		self.variables = variables
		self.type = type
		self.substitutions = substitutions
	}

	public var debugDescription: String {
		if let name {
			"\(name), variables(\(variables.map(\.debugDescription).joined(separator: ", "))), type: \(type.debugDescription))"
		} else {
			"variables(\(variables.map(\.debugDescription).joined(separator: ", "))), type: \(type.debugDescription))"
		}
	}

	public var description: String {
		if let name {
			"\(name), variables(\(variables.map(\.description).joined(separator: ", "))), type: \(type))"
		} else {
			"variables(\(variables.map(\.description).joined(separator: ", "))), type: \(type))"
		}
	}
}
