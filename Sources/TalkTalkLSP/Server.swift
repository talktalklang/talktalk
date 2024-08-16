//
//  Server.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Foundation
import TalkTalkSyntax
import TalkTalkAnalysis
import TalkTalkCompiler
import TalkTalkDriver

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
		self.stdlib = try await StandardLibrary.compile()
		Log.info("Compiled stdlib")
		self.analyzer = ModuleAnalyzer(
			name: "LSP",
			files: [],
			moduleEnvironment: ["Standard": stdlib.analysis],
			importedModules: [stdlib.analysis]
		)
		self.analysis = try analyzer.analyze()
	}

	func getSource(_ uri: String) -> SourceDocument? {
		sources[uri]
	}

	func setSource(uri: String, to document: SourceDocument) {
		sources[uri] = document
	}

	nonisolated func enqueue(_ request: Request) {
		Task {
			await _enqueue(request)
			await work()
		}
	}

	func work() {
		if worker != nil { return }

		self.worker = Task {
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

	func perform(_ request: Request) async {
		Log.info("handling request: \(request)")
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
		case .shutdown:
			Log.info("shutting down!")
			exit(0)
		}
	}

	func analyze() {
		do {
			analysis = try analyzer.analyze()
		} catch {
			Log.error("Error analyzing: \(error)")
		}

	}

	func findSyntaxLocation(from position: Position) -> Location? {
		let match = analysis.analyzedFiles
			.flatMap { file in
				file.syntax.compactMap {
					$0.nearestTo(
						line: position.line,
						column: position.character
					)
				}
			}.sorted { lhs, rhs in
				lhs.location.range.count < rhs.location.range.count
			}.first

		if let match {
			let location = match.location
			return Location(
				uri: location.path,
				range: Range(
					start: Position(line: location.start.line, character: location.start.column),
					end: Position(line: location.end.line, character: location.end.column)
				)
			)
		}

		return nil
	}

	func request<T: Encodable>(_ request: T) {
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

	func respond<T: Codable>(to id: RequestID?, with response: T) {
		do {
			let response = Response(id: id, result: response)
			let content = try encoder.encode(response)
			let contentLength = content.count
			var data = Data("Content-Length: \(contentLength)\r\n\r\n".utf8)
			data.append(content)
			try stdout.write(contentsOf: data)

			let dataString = String(data: data, encoding: .utf8)!
			Log.info(dataString)
		} catch {
			Log.error("error generating response: \(error)")
		}
	}
}
