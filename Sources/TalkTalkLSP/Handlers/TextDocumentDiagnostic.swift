//
//  TextDocumentDiagnostic.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import TalkTalkAnalysis

struct TextDocumentDiagnostic: Decodable {
	var request: Request

	func handle(_ handler: inout Handler) {
		let params = request.params as! TextDocumentDiagnosticRequest
		
		guard let source = handler.sources[params.textDocument.uri] else {
			Log.error("no source found for \(params.textDocument.uri)")
			return
		}

		do {
			let errorSyntaxes = try Analyzer.diagnostics(text: source.text)
			let diagnostics = errorSyntaxes.compactMap { syntax in
				let start = syntax.location.start
				let end = syntax.location.end

				return Diagnostic(
					range: Range(start: Position(line: start.line, character: start.column), end: Position(line: end.line, character: end.column)),
					severity: .error,
					message: syntax.message,
					tags: nil,
					relatedInformation: nil
				)
			}

			let report = FullDocumentDiagnosticReport(items: diagnostics)
			handler.respond(to: request.id, with: report)
		} catch {
			Log.error("Error generating diagnostics: \(error)")
		}
	}
}
