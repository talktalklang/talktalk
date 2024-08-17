//
//  HoverParams.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/5/24.
//

protocol HoverParams {
	var textDocument: String { get } /** The text document's URI in string form */
	var position: Position { get }
}

protocol HoverResult {
	var value: String { get }
}
