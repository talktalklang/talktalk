//
//  Server.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Foundation
import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompilerV1
import TalkTalkCore
import TypeChecker

@MainActor
public class Server {
	// We read json, we write json
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()

	// Responses are just written to stdout
	let stdout = FileHandle.standardOutput

	// Keep track of requests in progress
	var cancelled: Set<RequestID> = []

	// Keep track of our files
	var sources: [String: SourceDocument] = [:]

	// Saved diagnostics
	var diagnostics: [Diagnostic] = []

	init() throws {
		Log.info("Server initialized")
	}

	var analyzedFilePaths: [String] {
		sources.keys.sorted()
	}

	func setSource(uri: String, to document: SourceDocument) throws {
		sources[uri] = document

		let analysis = analyze()

		self.diagnostics = try analysis.collectErrors(for: uri).file.map { $0.diagnostic() }
	}

	func enqueue(_ request: Request) throws {
		if let id = request.id, cancelled.contains(id) {
			Log.info("skipping canceled job (\(id))", color: .default)
			cancelled.remove(id)
			return
		}

		try perform(request)
	}

	func perform(_ request: Request) throws {
		Log.info("-> \(request.method)", color: .magenta)

		switch request.method {
		case .initialize:
			respond(to: request.id, with: InitializeResult())
		case .initialized:
			()
		case .textDocumentDidClose:
			()
		case .cancelRequest:
			guard let params = request.params as? CancelParams else {
				Log.error("Could not parse CancelParams")
				return
			}
			cancelled.insert(params.id)
		case .textDocumentDefinition:
			guard let params = request.params as? TextDocumentDefinitionRequest else {
				Log.error("Could not parse TextDocumentDefinitionRequest params")
				return
			}

			Log.info("files: \(analyzedFilePaths)")

			if let match = findDefinition(
				from: params.position,
				path: params.textDocument.uri
			) {
				respond(
					to: request.id,
					with: Location(
						uri: match.location.path,
						range: Range(
							start: Position(line: match.location.start.line, character: match.location.start.column),
							end: Position(line: match.location.start.line, character: match.location.start.column + match.location.start.length)
						)
					)
				)
			}
		case .textDocumentDidOpen:
			guard let params = request.params as? TextDocumentDidOpenRequest else {
				Log.error("Could not parse TextDocumentDidOpenRequest params")
				return
			}

			try setSource(uri: params.textDocument.uri, to: .init(textDocument: params.textDocument))
		case .textDocumentDidChange:
			guard let params = request.params as? TextDocumentDidChangeRequest else {
				Log.error("Could not parse TextDocumentDidChangeRequest params")
				return
			}

			var source = if let source = sources[params.textDocument.uri] {
				source
			} else {
				SourceDocument(
					version: params.textDocument.version,
					uri: params.textDocument.uri,
					text: params.contentChanges[0].text
				)
			}

			source.update(text: params.contentChanges[0].text)
			try setSource(uri: params.textDocument.uri, to: source)

			sources[params.textDocument.uri] = source

			Log.info("textDocumentDidChange", color: .magenta)
			Log.info(source.text, color: .magenta)
		case .textDocumentCompletion:
			guard let params = request.params as? TextDocumentCompletionRequest else {
				Log.error("Could not parse text document completion request params")
				return
			}

			Log.info("handling completion request at \(params.position), trigger: \(params.context)", color: .magenta)

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

			Log.info("completion request: \(completionRequest)", color: .magenta)

			let completions = analyze().completions(for: completionRequest) // .sorted()

			Log.info("! got completions: \(completions)", color: .magenta)

			let completionList = CompletionList(isIncomplete: true, items: completions.map {
				Log.info("we've got a completion: \($0)", color: .magenta)

				let kind: CompletionItemKind = switch $0.kind {
				case .function: .function
				case .method: .method
				case .property: .property
				case .type: .struct
				case .variable: .variable
				}

				return .init(label: $0.value, kind: kind)
			})

			respond(to: request.id, with: completionList)
			Log.info("<- Finished completion request", color: .magenta)
		case .textDocumentFormatting:
			respond(to: request.id, with: TextDocumentFormatting(request: request).format(sources))
		case .textDocumentDiagnostic:
			guard let params = request.params as? TextDocumentDiagnosticRequest else {
				Log.error("Could not parse TextDocumentDiagnosticRequest params")
				return
			}

			Log.info("Diagnostic count: \(diagnostics.count)")
			let report = FullDocumentDiagnosticReport(items: diagnostics)
			respond(to: request.id, with: report)
		case .textDocumentSemanticTokensFull:
			try respond(to: request.id, with: TextDocumentSemanticTokensFull(request: request).handle(sources))
		case .workspaceSemanticTokensRefresh:
			()
		case .textDocumentPublishDiagnostics:
			()
		case .shutdown:
			Log.info("shutting down!")
			exit(0)
		}
	}

	func analyze() -> AnalysisModule {
		do {
			Log.info("Analyzing LSP module...")

			let analyzer = try ModuleAnalyzer(
				name: "LSP",
				files: sources.values.map { try Parser.parseFile(.init(path: $0.uri, text: $0.text), allowErrors: true) },
				moduleEnvironment: [:],
				importedModules: []
			)

			return try analyzer.analyze()
		} catch {
			Log.error("Error analyzing: \(error)")
			return AnalysisModule.empty("LSP")
		}
	}

	func findDefinition(from position: Position, path: String) -> Definition? {
		let analysis = analyze()

		Log.info("findDefinition: path: \(path) position: \(position)")

		let match = analysis.findSymbol(
			line: position.line,
			column: position.character,
			path: path
		)

		guard let match else {
			return nil
		}

		return match.definition()
	}

	func request(_ request: some Encodable) {
		do {
			let content = try encoder.encode(request)
			let contentLength = content.count
			var data = Data("Content-Length: \(contentLength)\r\n\r\n".utf8)
			data.append(content)
			try stdout.write(contentsOf: data)
		} catch {
			Log.error("Error issuing server request")
		}
	}

	func respond(to id: RequestID?, with response: some Codable) {
		do {
			let response = Response(id: id, result: response)
			let content = try encoder.encode(response)
			let contentLength = content.count
			var data = Data("Content-Length: \(contentLength)\r\n\r\n".utf8)
			data.append(content)
			try stdout.write(contentsOf: data)
		} catch {
			Log.error("error generating response: \(error)")
		}
	}
}
