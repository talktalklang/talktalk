enum Method: String {
	case initialize = "initialize",
			 initialized = "initialized",
			 shutdown = "shutdown",
			 textDocumentDidChange = "textDocument/didChange",
			 textDocumentCompletion = "textDocument/completion"
}
