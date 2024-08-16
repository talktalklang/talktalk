//
//  Server.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Foundation
import TalkTalkDriver
import TalkTalkAnalysis
import TalkTalkCompiler

public actor Server {
	// We read json, we write json
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()

	// Responses are just written to stdout
	let stdout = FileHandle.standardOutput

	// Keep track of our files
	var sources: [String: SourceDocument] = [:]

	var stdlib: CompilationResult
	var analysis: ModuleAnalyzer

	init() async throws {
		self.stdlib = try await StandardLibrary.compile()
		self.analysis = ModuleAnalyzer(
			name: "LSP",
			files: [],
			moduleEnvironment: ["Standard": stdlib.analysis],
			importedModules: [stdlib.analysis]
		)
	}

	func callback(_ request: Request) {
		
	}

	func getSource(_ uri: String) -> SourceDocument? {
		sources[uri]
	}

	func setSource(uri: String, to document: SourceDocument) {
		sources[uri] = document
	}

	func handle(_ request: Request) async {
		Log.info("handling request: \(request)")
		switch request.method {
		case .initialize:
			respond(to: request.id, with: InitializeResult())
		case .initialized:
			()
		case .textDocumentDidClose:
			()
		case .cancelRequest:
			()
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
