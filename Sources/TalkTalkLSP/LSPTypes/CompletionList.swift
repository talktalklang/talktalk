//
//  CompletionList.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct CompletionList: Encodable {
	let isIncomplete: Bool
	let items: [CompletionItem]
}
