enum Method: String, Codable {
	case initialize = "initialize",
			 initialized = "initialized",
			 shutdown = "shutdown",
			 cancelRequest = "$/cancelRequest",
			 textDocumentDidOpen = "textDocument/didOpen",
			 textDocumentDidClose = "textDocument/didClose",
			 textDocumentDidChange = "textDocument/didChange",
			 textDocumentCompletion = "textDocument/completion",
			 textDocumentFormatting = "textDocument/formatting",
			 textDocumentSemanticTokensFull = "textDocument/semanticTokens/full",
			 textDocumentDiagnostic = "textDocument/diagnostic",
			 workspaceSemanticTokensRefresh = "workspace/semanticTokens/refresh"
}
