//
//  TextDocumentDiagnosticRequest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocumentDiagnosticRequest: Decodable {
	let range: Range?
	let textDocument: TextDocument
}
