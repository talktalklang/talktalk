//
//  Formatter.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/13/24.
//
public struct Formatter {
	let input: SourceFile

	public init(input: SourceFile) {
		self.input = input
	}

	public func format(width: Int = 84) throws -> String {
		var parser = Parser(Lexer(input, preserveComments: true))

		let ast = parser.parse()
		var last: (any Syntax)? = nil
		var output = ""

		if ast.isEmpty {
			var lastComment: Token?
			for comment in parser.lexer.comments {
				if let last = lastComment {
					switch comment.line - last.line {
					case 0: output += "\n"
					case 1: output += "\n"
					default: output += "\n\n"
					}
				}

				output += format(
					document: .text(comment.lexeme),
					width: width
				)

				lastComment = comment
			}
		}

		let visitor = FormatterVisitor(commentsStore: CommentStore(comments: parser.lexer.comments))
		let context = FormatterVisitor.Context(kind: .topLevel)

		for syntax in ast {
			if let lastNode = last {
				switch syntax.location.start.line - lastNode.location.end.line {
				case 0: output += "\n"
				case 1: output += "\n"
				default: output += "\n\n"
				}
			}

			last = syntax

			output += try format(
				document: syntax.accept(visitor, context),
				width: width
			)
		}

		return output
	}

	func format(document: Doc, width: Int) -> String {
		var output = ""
		var queue: [(UInt8, Doc)] = [(0, document)]
		var column = 0
		var wasNewline = false

		while !queue.isEmpty {
			let (indent, currentDoc) = queue.removeFirst()
			switch currentDoc {
			case .empty:
				continue
			case let .text(str):
				if wasNewline {
					// Only indent if the previous line wasn't a newline
					output += String(repeating: "\t", count: Int(indent))
					wasNewline = false
				}
				output += str
				column += str.count
			case .line, .softline, .hardline:
				output += "\n"
				wasNewline = true
				column = 0
			case let .concat(lhs, rhs):
				queue.insert((indent, rhs), at: 0)
				queue.insert((indent, lhs), at: 0)
			case let .nest(ind, nestedDoc):
				queue.insert((indent + ind, nestedDoc), at: 0)
			case let .group(groupedDoc):
				let flat = flatten(groupedDoc)
				// Use the current column position in the calculation
				if fits(width - column, doc: flat) {
					queue.insert((indent, flat), at: 0)
				} else {
					queue.insert((indent, groupedDoc), at: 0)
				}
			}
		}
		return output
	}

	func peekBlankLine(queue: [(Int, Doc)]) -> Bool {
		if let first = queue.first {
			return first.1.isLineBreak
		}

		return false
	}

	func flatten(_ doc: Doc) -> Doc {
		switch doc {
		case .empty, .text:
			doc
		case .hardline:
			.hardline
		case .softline:
			.text("")
		case .line:
			.text(" ")
		case let .concat(left, right):
			.concat(flatten(left), flatten(right))
		case let .nest(indent, nestedDoc):
			.nest(indent, flatten(nestedDoc))
		case let .group(groupedDoc):
			flatten(groupedDoc)
		}
	}

	func fits(_ remainingWidth: Int, doc: Doc) -> Bool {
		var width = remainingWidth
		var queue: [Doc] = [doc]

		while width >= 0, !queue.isEmpty {
			let currentDoc = queue.removeFirst()
			switch currentDoc {
			case .empty:
				continue
			case let .text(str):
				width -= str.count
			case .line:
				return true
			case .softline:
				return true
			case .hardline:
				return true
			case let .concat(left, right):
				queue.insert(right, at: 0)
				queue.insert(left, at: 0)
			case let .nest(_, nestedDoc):
				queue.insert(nestedDoc, at: 0)
			case let .group(groupedDoc):
				queue.insert(groupedDoc, at: 0)
			}
		}
		return width >= 0
	}
}
