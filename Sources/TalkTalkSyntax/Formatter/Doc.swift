//
//  Doc.swift
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

	// Adds indentation to a document.
	//
	// Note: This is stored as a UInt8 because using Int was causing circular reference
	// errors for some reason in the swift compiler.
	case nest(UInt8, Doc)

	// Two documents that need to be concatenated
	case concat(Doc, Doc)

	// A choice between two layouts for a document
	case group(Doc)

	var isEmpty: Bool {
		switch self {
		case .empty: true
		default: false
		}
	}

	var isLineBreak: Bool {
		switch self {
		case .line, .softline, .hardline:
			true
		default:
			false
		}
	}
}

extension Doc {
	// Return a concat of these two documents
	static func <> (lhs: Doc, rhs: Doc) -> Doc {
		.concat(lhs, rhs)
	}

	// Return a concat of these two documents with a space
	static func <+> (lhs: Doc, rhs: Doc) -> Doc {
		lhs <> .text(" ") <> rhs
	}
}
