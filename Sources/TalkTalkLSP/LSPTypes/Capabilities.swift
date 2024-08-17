//
//  Capabilities.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

enum Capability: String, Codable {
	case hover = "textDocument/hover",
	     completion = "textDocument/completion"
}
