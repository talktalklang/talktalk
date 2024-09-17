//
//  Scheme.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

public struct Scheme: Equatable, CustomStringConvertible, CustomDebugStringConvertible, Hashable {
	public let name: String?
	let variables: [InferenceType]
	let type: InferenceType

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
