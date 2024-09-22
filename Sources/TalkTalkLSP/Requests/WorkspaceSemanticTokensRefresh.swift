//
//  WorkspaceSemanticTokensRefresh.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct WorkspaceSemanticTokensRefresh: Encodable {
	let id: RequestID?
	let method = "workspace/semanticTokens/refresh"
}
