//
//  TextDocumentCompletion.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import TalkTalkAnalysis

struct TextDocumentCompletion {
	var request: Request

	func handle(_ server: Server) async {
		guard let params = request.params as? TextDocumentCompletionRequest else {
			Log.error("Could not parse text document completion request params")
			return
		}

		Log.info("handling completion request at \(params.position), trigger: \(params.context)")

		let trigger: Completion.Trigger? = if let char = params.context.triggerCharacter {
			.character(char)
		} else {
			nil
		}

		let completionRequest = Completion.Request(
			documentURI: params.textDocument.uri,
			line: params.position.line,
			column: params.position.character,
			trigger: trigger
		)

		Log.info("completion request: \(completionRequest)")

		let completions = await server.completions(for: completionRequest)
		let completionList = CompletionList(isIncomplete: true, items: completions.map {
			let kind: CompletionItemKind = switch $0.kind {
			case .function: .function
			case .method: .method
			case .property: .property
			case .type: .struct
			case .variable: .variable
			}

			return .init(label: $0.value, kind: kind)
		})

		await server.respond(to: request.id, with: completionList)
	}
}
