//
//  Document.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/13/24.
//

indirect enum Doc {
	// The empty document
	case empty

	// Some text to be printed
	case text(String)

	// A line break that collapses to a space
	case line

	// A line break that collapses to nothing
	case softline

	// A line break that does not collapse
	case hardline

	// Adds indentation to a document
	case nest(Int, Doc)

	// Two documents that need to be concatenated
	case concat(Doc, Doc)

	// A choice between two layouts for a document
	case group(Doc)
}

extension Doc: Equatable {
	static func ==(lhs: Doc, rhs: Doc) -> Bool {
		switch (lhs, rhs) {
		case (.empty, .empty):
			return true
		case (.text(let lText), .text(let rText)):
			return lText == rText
		case (.line, .line):
			return true
		case (.softline, .softline):
			return true
		case (.hardline, .hardline):
			return true
		case (.nest(let lIndent, let lDoc), .nest(let rIndent, let rDoc)):
			return lIndent == rIndent && lDoc == rDoc
		case (.concat(let lLeft, let lRight), .concat(let rLeft, let rRight)):
			return lLeft == rLeft && lRight == rRight
		case (.group(let lDoc), .group(let rDoc)):
			return lDoc == rDoc
		default:
			return false
		}
	}
}

extension Doc {
	// Return a concat of these two documents
	static func <>(lhs: Doc, rhs: Doc) -> Doc {
		.concat(lhs, rhs)
	}

	// Return a concat of these two documents with a space
	static func <+>(lhs: Doc, rhs: Doc) -> Doc {
		lhs <> .text(" ") <> rhs
	}
}
