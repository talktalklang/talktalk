//
//  TextDocumentDidChange.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

struct TextDocumentDidChange {
	var request: Request

	func handle(_ server: Server) async {
		guard let params = request.params as? TextDocumentDidChangeRequest else {
			Log.error("Could not parse TextDocumentDidChangeRequest params")
			return
		}

		let source = if let source = await server.sources[params.textDocument.uri] {
			source
		} else {
			await SourceDocument(
				version: params.textDocument.version,
				uri: params.textDocument.uri,
				text: params.contentChanges[0].text
			)
		}

		await source.update(text: params.contentChanges[0].text)
		await server.setSource(uri: params.textDocument.uri, to: source)
		await server.analyze()

		// Update the diagnostics for the file:
//		do {
//			let diagnostics = try await server.diagnostics(for: source.uri)
//			let params = try await PublishDiagnosticsParams(
//				uri: source.uri,
//				diagnostics: server.diagnostics()
//			)
//
//			Log.info("Publishing \(diagnostics.count) \(diagnostics) after update")
//
//			await server.request(
//				Request(
//					id: nil,
//					method: .textDocumentPublishDiagnostics,
//					params: params
//				)
//			)
//		} catch {
//			Log.error("error publishing diagnostics: \(error)")
//		}
	}
}
