enum Method: String, Decodable {
	case initialize = "initialize",
			 initialized = "initialized",
			 shutdown = "shutdown",
			 textDocumentDidChange = "textDocument/didChange",
			 textDocumentCompletion = "textDocument/completion",
			 textDocumentFormatting = "textDocument/formatting"
}
