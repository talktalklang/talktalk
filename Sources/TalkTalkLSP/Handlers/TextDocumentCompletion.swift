//
//  TextDocumentCompletion.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocumentCompletion {
	var request: Request

	func handle(_ handler: inout Server) {
		let params = request.params as! TextDocumentCompletionRequest
		Log.info("handling completion request at \(params.position)")

		guard let source = handler.sources[params.textDocument.uri] else {
			Log.error("no source found for \(params.textDocument.uri)")
			return
		}

		// TODO: probably don't need to new up one of these for every request
		let completer = Completer(source: source.text)

		do {
			let completionItems = try completer.completions(at: params.position)
			Log.info("got completions: \(completionItems)")

			let completionList = CompletionList(isIncomplete: true, items: completionItems)

			Log.info("generated completion list: \(completionList)")

			handler.respond(to: request.id, with: completionList)
		} catch {
			Log.error("error getting completion results: \(error)")
		}
	}
}
