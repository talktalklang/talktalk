//
//  CompletionList.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct CompletionList: Codable {
	let isIncomplete: Bool
	let items: [CompletionItem]
}
