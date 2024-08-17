//
//  Location.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

public struct Location: Codable, Sendable, Hashable {
	let uri: String
	let range: Range
}
