//
//  Scheme.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

struct Scheme: Equatable, CustomStringConvertible, Hashable {
	let name: String?
	let variables: [InferenceType]
	let type: InferenceType

	var description: String {
		if let name {
			"\(name), variables(\(variables.map(\.description).joined(separator: ", "))), type: \(type))"
		} else {
			"variables(\(variables.map(\.description).joined(separator: ", "))), type: \(type))"
		}
	}
}
