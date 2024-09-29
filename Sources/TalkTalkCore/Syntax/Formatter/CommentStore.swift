//
//  CommentStore.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/14/24.
//

extension Syntax {
	var canHaveLeadingComment: Bool {
		!(self is DeclBlock)
	}

	var canHaveTrailingComment: Bool {
		self is Decl || self is Stmt
	}
}

struct CommentSet {
	var isFirstChild = true
	var leadingComments: [Token] = []
	var trailingComments: [Token] = []
	var danglingComments: [Token] = []

	var leading: Doc {
		if leadingComments.isEmpty {
			return .empty
		}

		return join(
			leadingComments.map { .text($0.lexeme) }, with: .hardline
		) <> .hardline
	}

	var trailing: Doc {
		if trailingComments.isEmpty {
			return .empty
		}

		return .hardline <> join(
			trailingComments.map { .text($0.lexeme) }, with: .hardline
		)
	}

	var dangling: Doc {
		if danglingComments.isEmpty {
			return .empty
		}

		let result = join(
			danglingComments.map { .text($0.lexeme) }, with: .line
		)

		if isFirstChild {
			return .text(" ") <> result
		} else {
			return result
		}
	}

	private func join(_ documents: [Doc], with separator: Doc) -> Doc {
		documents.reduce(.empty) { res, doc in
			res.isEmpty ? doc : res <> separator <> doc
		}
	}
}

// The comment store creates a CommentSet for a given syntax node.
class CommentStore {
	private var comments: [Token]
	private var commentsBySyntax: [SyntaxID: CommentSet] = [:]

	init(comments: [Token]) {
		self.comments = comments
	}

	func handle(comment: Token, syntax: any Syntax, previous: (any Syntax)?) -> Bool {
		commentsBySyntax[syntax.id, default: .init()].isFirstChild = previous == nil

		// It's before the node, make it a leading comment
		if comment.line < syntax.location.start.line, syntax.canHaveLeadingComment {
			commentsBySyntax[syntax.id, default: .init()].leadingComments.append(comment)
			comments.removeFirst()
			return true
		}

		// It's right after the node, make it a trailing comment
		if comment.line - 1 == syntax.location.end.line, syntax.canHaveTrailingComment {
			commentsBySyntax[syntax.id, default: .init()].trailingComments.append(comment)
			comments.removeFirst()
			return true
		}

		// It's inside the node, but let's check if there are child nodes
		var lastChild: (any Syntax)? = nil
		for child in syntax.children {
			// Recursively call `get` for the child node to attach the comment to it
			if handle(comment: comment, syntax: child, previous: lastChild) {
				return true
			}

			lastChild = child
		}

		if comment.line >= syntax.location.start.line, comment.line <= syntax.location.end.line {
			// It's inside the node, make it a dangling comment
			commentsBySyntax[syntax.id, default: .init()].danglingComments.append(comment)
			comments.removeFirst()
			return true
		}

		return false
	}

	func get(for syntax: any Syntax, context: FormatterVisitor.Context) -> CommentSet {
		var lastComment: Token?

		while let comment = comments.first {
			let didHandle = handle(comment: comment, syntax: syntax, previous: context.lastNode)

			if !didHandle, lastComment == comment {
				break
			}

			lastComment = comment
		}

		return commentsBySyntax[syntax.id, default: .init()]
	}
}
