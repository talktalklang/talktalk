//
//  TextDocumentCompletion.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocumentCompletion {
	var request: Request

	func handle(_ server: inout Server) {
		let params = request.params as! TextDocumentCompletionRequest
		Log.info("handling completion request at \(params.position), trigger: \(params.context)")

		guard let source = server.sources[params.textDocument.uri] else {
			Log.error("no source found for \(params.textDocument.uri)")
			return
		}

		// TODO: probably don't need to new up one of these for every request

		do {
			let completionItems = try source.completer.completions(from: params)
			Log.info("got completions: \(completionItems)")

			let completionList = CompletionList(isIncomplete: true, items: completionItems)

			Log.info("generated completion list: \(completionList)")

			server.respond(to: request.id, with: completionList)
		} catch {
			Log.error("error getting completion results: \(error)")
		}
	}
}
