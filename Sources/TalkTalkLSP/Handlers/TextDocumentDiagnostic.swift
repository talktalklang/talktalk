//
//  TextDocumentDiagnostic.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import TalkTalkAnalysis
import TalkTalkSyntax

extension AnalysisError {
	func diagnostic() -> Diagnostic {
		let start = location.start
		let end = location.end

		return Diagnostic(
			range: Range(
				start: Position(line: start.line, character: start.column),
				end: Position(line: end.line, character: end.column)
			),
			severity: .error,
			message: message,
			tags: nil,
			relatedInformation: nil
		)
	}

}

struct TextDocumentDiagnostic: Decodable {
	var request: Request

	func handle(_ server: Server) async {
		guard let params = request.params as? TextDocumentDiagnosticRequest else {
			Log.error("Could not parse TextDocumentDiagnosticRequest params")
			return
		}

		Log.info("requesting diagnostics for \(params.textDocument.uri)")

		do {
			let diagnostics = try await server.diagnostics(for: params.textDocument.uri)
			Log.info("Diagnostic count: \(diagnostics.count)")
			let report = FullDocumentDiagnosticReport(items: diagnostics)
			await server.respond(to: request.id, with: report)
		} catch {
			Log.error("Error generating diagnostics: \(error)")
		}
	}
}
