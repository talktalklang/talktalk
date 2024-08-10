//
//  CompletionOptions.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

struct CompletionOptions: Codable {
	enum CodingKeys: CodingKey {
		case triggerCharacters
	}

	let triggerCharacters: [String] = ["."]
}
