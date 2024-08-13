//
//  Server.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import Foundation

public struct Server {
	// We read json, we write json
	let decoder = JSONDecoder()
	let encoder = JSONEncoder()

	// Responses are just written to stdout
	let stdout = FileHandle.standardOutput

	// Keep track of our files
	var sources: [String: SourceDocument] = [:]

	mutating func handle(_ request: Request) {
		switch request.method {
		case .initialize:
			respond(to: request.id, with: InitializeResult())
		case .initialized:
			()
		case .textDocumentDidClose:
			()
		case .textDocumentDidOpen:
			TextDocumentDidOpen(request: request).handle(&self)
		case .textDocumentDidChange:
			TextDocumentDidChange(request: request).handle(&self)
		case .textDocumentCompletion:
			TextDocumentCompletion(request: request).handle(&self)
		case .textDocumentFormatting:
			TextDocumentFormatting(request: request).handle(&self)
		case .textDocumentDiagnostic:
			TextDocumentDiagnostic(request: request).handle(&self)
		case .textDocumentSemanticTokensFull:
			TextDocumentSemanticTokensFull(request: request).handle(&self)
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
