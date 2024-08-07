//
//  WorkspaceSemanticTokensRefresh.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import Foundation

struct WorkspaceSemanticTokensRefresh: Encodable {
	let id: RequestID?
	let method = "workspace/semanticTokens/refresh"
}
