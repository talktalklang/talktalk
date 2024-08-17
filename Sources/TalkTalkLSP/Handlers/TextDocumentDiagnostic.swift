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

	var message: String {
		switch kind {
		case let .argumentError(expected: a, received: b):
			if a == -1 {
				"Unable to determine expected arguments, probably because callee isn't callable."
			} else {
				"Expected \(a) arguments, got: \(b)"
			}
		case let .typeParameterError(expected: a, received: b):
			"Expected \(a) type parameters, got: \(b)"
		case let .typeNotFound(name):
			"Unknown type: \(name)"
		case let .unknownError(message):
			message
		case let .noMemberFound(receiver: receiver, property: property):
			"No property named `\(property)` for \(receiver)"
		case let .undefinedVariable(name):
			"Undefined variable `\(name)`"
		case let .typeCannotAssign(expected: expected, received: received):
			"Cannot assign \(received) to \(expected)"
		case let .cannotReassignLet(variable: syntax):
			"Cannot re-assign let variable: \(syntax.description)"
		case let .invalidRedeclaration(variable: name, existing: decl):
			"Cannot re-declare \(name)."
		}
	}
}

struct TextDocumentDiagnostic: Decodable {
	var request: Request

	func handle(_ server: Server) async {
		let params = request.params as! TextDocumentDiagnosticRequest

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
