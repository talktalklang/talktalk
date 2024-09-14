enum Method: String, Codable {
	case initialize,
	     initialized,
	     shutdown,
	     cancelRequest = "$/cancelRequest",
	     textDocumentDefinition = "textDocument/definition",
	     textDocumentPublishDiagnostics = "textDocument/publishDiagnostics",
	     textDocumentDidOpen = "textDocument/didOpen",
	     textDocumentDidClose = "textDocument/didClose",
	     textDocumentDidChange = "textDocument/didChange",
	     textDocumentCompletion = "textDocument/completion",
	     textDocumentFormatting = "textDocument/formatting",
	     textDocumentSemanticTokensFull = "textDocument/semanticTokens/full",
	     textDocumentDiagnostic = "textDocument/diagnostic",
	     workspaceSemanticTokensRefresh = "workspace/semanticTokens/refresh"
}
