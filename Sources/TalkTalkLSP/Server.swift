//
//  Server.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Foundation
import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkCore
import TalkTalkDriver
import TalkTalkSyntax
import TypeChecker

public struct Server {
	// We read json, we write json
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()

	// Responses are just written to stdout
	let stdout = FileHandle.standardOutput

	// Keep track of requests in progress
	var cancelled: Set<RequestID> = []

	// Keep track of our files
	var sources: [String: SourceDocument] = [:]

	var analyzer: ModuleAnalyzer
	var analysis: AnalysisModule

	init() throws {
		Log.info("Compiled stdlib")

		self.analyzer = try ModuleAnalyzer(
			name: "LSP",
			files: [],
			moduleEnvironment: [:],
			importedModules: []
		)

		self.analysis = try analyzer.analyze()
	}

	var analyzedFilePaths: [String] {
		analysis.analyzedFiles.map(\.path)
	}

	func getSource(_ uri: String) -> SourceDocument? {
		sources[uri]
	}

	mutating func setSource(uri: String, to document: SourceDocument) {
		sources[uri] = document

		do {
			analysis = try analyzer.addFile(
				ParsedSourceFile(
					path: document.uri,
					syntax: Parser.parse(
						SourceFile(path: document.uri, text: document.text),
						allowErrors: true
					)
				)
			)
		} catch {
			Log.error("error adding file to analyzer: \(error)")
		}
	}

	mutating func enqueue(_ request: Request) {
		if let id = request.id, cancelled.contains(id) {
			Log.info("skipping canceled job (\(id))", color: .default)
			cancelled.remove(id)
			return
		}

		perform(request)
	}

	mutating func diagnostics(for uri: String? = nil) throws -> [Diagnostic] {
		analyze()

		let errorResult = try analysis.collectErrors(for: uri)

		Log.info("error result, \(errorResult.count) total, \(errorResult.file.count) file")

		return errorResult.file.map {
			$0.diagnostic()
		}
	}

	mutating func perform(_ request: Request) {
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

			setSource(uri: params.textDocument.uri, to: .init(textDocument: params.textDocument))
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
			setSource(uri: params.textDocument.uri, to: source)
			analyze()

			sources[params.textDocument.uri] = source
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

			let completions = analysis.completions(for: completionRequest) // .sorted()

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

			Log.info("requesting diagnostics for \(params.textDocument.uri)")

			do {
				let diagnostics = try diagnostics(for: params.textDocument.uri)
				Log.info("Diagnostic count: \(diagnostics.count)")
				let report = FullDocumentDiagnosticReport(items: diagnostics)
				respond(to: request.id, with: report)
			} catch {
				Log.error("Error generating diagnostics: \(error)")
			}
		case .textDocumentSemanticTokensFull:
			respond(to: request.id, with: TextDocumentSemanticTokensFull(request: request).handle(sources))
		case .workspaceSemanticTokensRefresh:
			()
		case .textDocumentPublishDiagnostics:
			()
		case .shutdown:
			Log.info("shutting down!")
			exit(0)
		}
	}

	mutating func analyze() {
		do {
			Log.info("Compiled stdlib")

			analyzer = try ModuleAnalyzer(
				name: "LSP",
				files: analyzer.files,
				moduleEnvironment: [:],
				importedModules: []
			)

			analysis = try analyzer.analyze()
		} catch {
			Log.error("Error analyzing: \(error)")
		}
	}

	mutating func findDefinition(from position: Position, path: String) -> Definition? {
		do {
			analysis = try analyzer.analyze()
		} catch {
			Log.error("Error finding definition: \(error)")
			return nil
		}

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
