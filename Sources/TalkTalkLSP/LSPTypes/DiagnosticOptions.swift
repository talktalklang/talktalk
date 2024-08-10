//
//  DiagnosticOptions.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct DiagnosticOptions: Codable {
	enum CodingKeys: CodingKey {
		case interFileDependencies
	}

	let interFileDependencies = true
}
