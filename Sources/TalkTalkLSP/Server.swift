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
import TalkTalkDriver
import TalkTalkSyntax
import TypeChecker

public actor Server {
	// We read json, we write json
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()

	// Responses are just written to stdout
	let stdout = FileHandle.standardOutput

	// Keep track of requests in progress
	var queue: [Request] = []
	var worker: Task<Void, Never>?
	var cancelled: Set<RequestID> = []

	// Keep track of our files
	var sources: [String: SourceDocument] = [:]

	var stdlib: CompilationResult
	var analyzer: ModuleAnalyzer
	var analysis: AnalysisModule

	init() async throws {
		stdlib = try await StandardLibrary.compile(allowErrors: true)
		Log.info("Compiled stdlib")

		analyzer = ModuleAnalyzer(
			name: "LSP",
			inferenceContext: Inferencer().infer([]),
			files: [],
			moduleEnvironment: ["Standard": stdlib.analysis],
			importedModules: [stdlib.analysis]
		)

		analysis = try analyzer.analyze()
	}

	var analyzedFilePaths: [String] {
		analysis.analyzedFiles.map(\.path)
	}

	func completions(for request: Completion.Request) -> [Completion.Item] {
		analysis.completions(for: request).sorted()
	}

	func getSource(_ uri: String) -> SourceDocument? {
		sources[uri]
	}

	func setSource(uri: String, to document: SourceDocument) async {
		sources[uri] = document

		do {
			analysis = try await analyzer.addFile(
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

	nonisolated func enqueue(_ request: Request) {
		Task {
			await _enqueue(request)
			await work()
		}
	}

	func work() {
		if worker != nil { return }

		worker = Task {
			while !queue.isEmpty {
				await Task.yield()

				Log.info("queue depth is \(queue.count), (\(cancelled.count) cancelled)")
				let next = queue.removeFirst()

				if let id = next.id, cancelled.contains(id) {
					Log.info("skipping canceled job (\(id))")
					cancelled.remove(id)
					continue
				}

				await self.perform(next)
			}

			self.worker = nil
			Log.info("done processing jobs")
		}
	}

	func _enqueue(_ request: Request) {
		queue.append(request)
	}

	func diagnostics(for uri: String? = nil) async throws -> [Diagnostic] {
		await analyze()

		let errorResult = try analysis.collectErrors(for: uri)

		Log.info("error result, \(errorResult.count) total, \(errorResult.file.count) file")

		return errorResult.file.map {
			$0.diagnostic()
		}
	}

	func perform(_ request: Request) async {
		Log.info("-> \(request.method)")
		switch request.method {
		case .initialize:
			respond(to: request.id, with: InitializeResult())
		case .initialized:
			()
		case .textDocumentDidClose:
			()
		case .cancelRequest:
			cancelled.insert((request.params as! CancelParams).id)
		case .textDocumentDefinition:
			await TextDocumentDefinition(request: request).handle(self)
		case .textDocumentDidOpen:
			await TextDocumentDidOpen(request: request).handle(self)
		case .textDocumentDidChange:
			await TextDocumentDidChange(request: request).handle(self)
		case .textDocumentCompletion:
			await TextDocumentCompletion(request: request).handle(self)
		case .textDocumentFormatting:
			await TextDocumentFormatting(request: request).handle(self)
		case .textDocumentDiagnostic:
			await TextDocumentDiagnostic(request: request).handle(self)
		case .textDocumentSemanticTokensFull:
			await TextDocumentSemanticTokensFull(request: request).handle(self)
		case .workspaceSemanticTokensRefresh:
			()
		case .textDocumentPublishDiagnostics:
			()
		case .shutdown:
			Log.info("shutting down!")
			exit(0)
		}
	}

	func analyze() async {
		do {
			stdlib = try await StandardLibrary.compile(allowErrors: true)
			Log.info("Compiled stdlib")

			analyzer = ModuleAnalyzer(
				name: "LSP",
				inferenceContext: analysis.inferenceContext,
				files: analyzer.files,
				moduleEnvironment: ["Standard": stdlib.analysis],
				importedModules: [stdlib.analysis]
			)

			analysis = try analyzer.analyze()
		} catch {
			Log.error("Error analyzing: \(error)")
		}
	}

	func findDefinition(from position: Position, path: String) -> Definition? {
		analysis = try! analyzer.analyze()

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
