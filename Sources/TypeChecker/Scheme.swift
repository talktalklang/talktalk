//
//  Scheme.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

public struct Scheme: Equatable, CustomStringConvertible, Hashable {
	public let name: String?
	let variables: [InferenceType]
	let type: InferenceType

	public var description: String {
		if let name {
			"\(name), variables(\(variables.map(\.description).joined(separator: ", "))), type: \(type))"
		} else {
			"variables(\(variables.map(\.description).joined(separator: ", "))), type: \(type))"
		}
	}
}
