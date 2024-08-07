enum Method: String, Decodable {
	case initialize = "initialize",
			 initialized = "initialized",
			 shutdown = "shutdown",
			 textDocumentDidOpen = "textDocument/didOpen",
			 textDocumentDidChange = "textDocument/didChange",
			 textDocumentCompletion = "textDocument/completion",
			 textDocumentFormatting = "textDocument/formatting",
			 textDocumentSemanticTokensFull = "textDocument/semanticTokens/full",
			 textDocumentDiagnostic = "textDocument/diagnostic",
			 workspaceSemanticTokensRefresh = "workspace/semanticTokens/refresh"
}
