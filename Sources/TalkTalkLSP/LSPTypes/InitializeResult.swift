//
//  InitializeResult.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

struct InitializeResult: Codable {
	enum CodingKeys: CodingKey {
		case capabilities
	}

	let capabilities: ServerCapabilities = .init()
}
