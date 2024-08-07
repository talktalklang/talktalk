//
//  TextDocumentSyncOptions.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

struct TextDocumentSyncOptions: Encodable {
	let change: TextDocumentSyncKind
	let openClose = true
}
