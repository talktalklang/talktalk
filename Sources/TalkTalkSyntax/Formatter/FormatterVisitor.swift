//
//  FormatterVisitor.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/13/24.
//

infix operator <>: AdditionPrecedence
infix operator <|>: AdditionPrecedence
infix operator <+>: AdditionPrecedence

struct FormatterVisitor: Visitor {
	let commentsStore: CommentStore

	typealias Value = Doc

	func visit(_ expr: CallExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let callee = try comments.leading <> expr.callee.accept(self, context)
		let args = try expr.args.map { try $0.accept(self, context) }

		return group(
			callee
				<> text("(")
				<> .nest(1, .softline <> join(args, with: text(",") <> .line))
				<> .softline
				<> text(")")
				<> comments.trailing
		)
	}

	func visit(_ expr: DefExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let lhs = try expr.receiver.accept(self, context)
		let rhs = try expr.value.accept(self, context)

		return comments.leading <> lhs <+> text(expr.op.lexeme) <+> rhs <> comments.trailing
	}

	func visit(_ expr: IdentifierExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		return comments.leading <> .text(expr.name) <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: LiteralExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let value: Doc = switch expr.value {
		case let .int(int):
			.text("\(int)")
		case let .bool(bool):
			.text("\(bool)")
		case let .string(string):
			.text(#"""# + StringParser.escape(string) + #"""#)
		case .none:
			.text("none")
		}

		return comments.leading <> value <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: VarExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		return comments.leading <> .text(expr.name) <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: UnaryExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let op = text("\(expr.op)")
		let expr = try expr.expr.accept(self, context)

		return comments.leading <> group(op <> expr) <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: BinaryExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let lhs = try expr.lhs.accept(self, context)
		let op = text("\(expr.op.rawValue)")
		let rhs = try expr.rhs.accept(self, context)

		return comments.leading <> group(lhs <+> op <+> rhs) <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: IfExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let condition = try expr.condition.accept(self, context)
		let consequence = try expr.consequence.accept(self, context)
		let alternative = try expr.alternative.accept(self, context)

		return comments.leading <> group(
			text("if") <+> condition <+> text("{")
				<> .nest(1, .line <> consequence) <> .line
				<> text("}") <+> text("else") <+> text("{")
				<> .nest(1, .line <> alternative) <> .line
				<> text("}")
		) <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: WhileStmtSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let condition = try expr.condition.accept(self, context)
		let body = try expr.body.accept(self, context)

		return comments.leading <> text("while") <+> condition <+> body <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: BlockStmtSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let context = context.copy()

		if expr.stmts.isEmpty {
			if comments.dangling.isEmpty {
				return comments.leading <> text("{}") <> comments.trailing
			} else {
				return comments.leading
					<> text("{") <> .hardline
					<> .nest(1, comments.dangling)
					<> .hardline <> text("}")
					<> comments.trailing
			}
		}

		let block = try comments.leading <> text("{")
			<> .nest(1, .line <> comments.dangling <> preservingNewlines(expr.stmts, in: context))
			<> .line
			<> text("}")
			<> comments.trailing

		// If there's only one statement, we can let the func be a one-liner
		if expr.stmts.count == 1, context.allowsSingleLineStmtBlock, !context.childTraits.has(.hasFunc), comments.dangling.isEmpty {
			return group(block)
		} else {
			// Otherwise, the body should be split
			return block
		}
	}

	func visit(_ expr: FuncExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		var start = comments.leading <> text("func")

		if let name = expr.name?.lexeme {
			start = start <+> text(name)
		}

		let params = try expr.params.accept(self, context)
		let body = try expr.body.accept(self, context)

		context.childTraits.add(.hasFunc)

		let type: Doc = if let type = expr.typeDecl {
			try text(" ->") <+> type.accept(self, context)
		} else {
			.empty
		}

		return start
			<> text("(")
			<> params
			<> text(")")
			<> type
			<+> body
			<> comments.dangling
			<> comments.trailing
	}

	func visit(_ expr: ParamsExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		return try comments.leading
			<> .group(join(expr.params.map { try $0.accept(self, context) }, with: text(",")))
			<> comments.dangling
			<> comments.trailing
	}

	func visit(_ expr: ParamSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		var result = comments.leading <> text(expr.name)

		if let type = expr.type {
			result = try result <> text(":") <+> type.accept(self, context)
		}

		return result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: GenericParamsSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		return try comments.leading <> .group(
			text("<")
				<> join(expr.params.map { try $0.type.accept(self, context) }, with: text(","))
				<> text(">")
				<> comments.dangling <> comments.trailing
		)
	}

	func visit(_ expr: Argument, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let value = try expr.value.accept(self, context)

		if let label = expr.label {
			return comments.leading <> group(
				text(label.lexeme) <> text(":") <+> value
			) <> comments.dangling <> comments.trailing
		} else {
			return comments.leading <> value <> comments.dangling <> comments.trailing
		}
	}

	func visit(_ expr: StructExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		var result = comments.leading <> text("struct") <+> text(expr.name ?? "")

		if !expr.typeParameters.isEmpty {
			result = try result
				<> text("<")
				<> join(expr.typeParameters.map { try $0.accept(self, context) }, with: text(","))
				<> text(">")
				<> comments.dangling <> comments.trailing
		}

		return try result <+> expr.body.accept(self, context)
	}

	func visit(_ expr: DeclBlockSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let context = context.in(.declBlock)
		let decls = try preservingNewlines(expr.decls, in: context)

		return comments.leading <> text("{")
			<> .nest(1, .line <> decls)
			<> .line
			<> text("}")
			<> comments.dangling <> comments.trailing
	}

	func visit(_ expr: VarDeclSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		return try comments.leading <> handleVarLet("var", expr: expr, in: context) <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: LetDeclSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		return try comments.leading <> handleVarLet("let", expr: expr, in: context) <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: ParseErrorSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		return comments.leading <> text(expr.message) <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: MemberExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let result: Doc = if let receiver = try expr.receiver?.accept(self, context) {
			group(receiver <> text("." + expr.property))
		} else {
			text("." + expr.property)
		}

		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: ReturnStmtSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let result: Doc = if let value = expr.value {
			try text("return") <+> value.accept(self, context)
		} else {
			text("return")
		}

		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: InitDeclSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let result = try text("init(")
			<> group(expr.params.accept(self, context))
			<> text(")")
			<+> expr.body.accept(self, context)

		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: ImportStmtSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)
		let result = text("import") <+> text(expr.module.name)
		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: TypeExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		if expr.genericParams.isEmpty {
			return text(expr.identifier.lexeme)
		}

		let result = try text(expr.identifier.lexeme)
			<> group(
				text("<")
					<> join(expr.genericParams.map { try $0.accept(self, context) }, with: text(","))
					<> text(">")
			)

		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: ExprStmtSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let result = try expr.expr.accept(self, context)

		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: IfStmtSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let condition = try expr.condition.accept(self, context)
		let consequence = try expr.consequence.accept(self, context)
		let alternative = try expr.alternative?.accept(self, context)

		let result = if let alternative {
			text("if") <+> condition <+> consequence <+> text("else") <+> alternative
		} else {
			text("if") <+> condition <+> consequence
		}

		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: StructDeclSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		var result = text("struct") <+> text(expr.name)

		if !expr.typeParameters.isEmpty {
			result = try result
				<> text("<")
				<> join(expr.typeParameters.map { try $0.accept(self, context) }, with: text(","))
				<> text(">")
		}

		result = try result <+> expr.body.accept(self, context)
		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: ArrayLiteralExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)
		let result = try group(text("[") <> .nest(1, .softline <> join(expr.exprs.map { try $0.accept(self, context) }, with: text(",") <> .line)) <> .softline <> text("]"))
		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: SubscriptExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let receiver = try expr.receiver.accept(self, context)
		let args = try join(expr.args.map { try $0.accept(self, context) }, with: text(","))

		let result = receiver <> text("[") <> args <> text("]")
		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: DictionaryLiteralExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)
		let result = try group(
			text("[")
				<> .nest(1, join(expr.elements.enumerated().map {
					try ($0 == 0 ? .softline : .line) <> $1.accept(self, context)
				}, with: text(",")))
				<> .softline
				<> text("]")
		)
		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: DictionaryElementExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)
		let result = try expr.key.accept(self, context) <> text(":") <+> expr.value.accept(self, context)
		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ syntax: ProtocolDeclSyntax, _ context: Context) throws -> Doc {
		try text("protocol") <+> text(syntax.name.lexeme) <+> syntax.body.accept(self, context)
	}

	func visit(_ body: ProtocolBodyDeclSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: body, context: context)

		let leading = comments.leading.isEmpty ? .empty : comments.leading

		return try text("{")
			<> .line
			<> comments.dangling
			<> .nest(1, leading <> preservingNewlines(body.decls, in: context))
			<> .line
			<> text("}") <> comments.trailing
	}

	func visit(_ decl: FuncSignatureDeclSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: decl, context: context)

		let start = comments.leading <> text("func") <+> text(decl.name.lexeme)
		let params = try decl.params.accept(self, context)
		let returns = try text(" ->") <+> decl.returnDecl.accept(self, context)

		return comments.leading
			<> start
			<> params
			<> returns
			<> comments.dangling <> comments.trailing
	}

	func visit(_ expr: EnumDeclSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		var result = text("enum") <+> text(expr.nameToken.lexeme)

		if !expr.typeParams.isEmpty {
			result = try result
				<> text("<")
				<> join(expr.typeParams.map { try $0.accept(self, context) }, with: text(","))
				<> text(">")
		}

		result = try result <+> expr.body.accept(self, context) <> .softline
		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: EnumCaseDeclSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		var result = text("case \(expr.nameToken.lexeme)")

		if !expr.attachedTypes.isEmpty {
			result = try result <> text("(") <> join(expr.attachedTypes.map { try $0.accept(self, context) }, with: text(",")) <> text(")")
		}

		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: MatchStatementSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let result = try text("match") <+> expr.target.accept(self, context) <+> text("{")
			<> .line
			<> join(expr.cases.map { try $0.accept(self, context) }, with: .line)
			<> .line
			<> text("}")
			<> .softline

		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_ expr: CaseStmtSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let result = if let pattern = expr.patternSyntax {
			try text("case") <+> pattern.accept(self, context)
				<> text(":")
				<> .line
				<> .nest(1, preservingNewlines(expr.body, in: context))
		} else {
			try text("else") <> .line <> join(expr.body.map { try $0.accept(self, context) }, with: .line)
		}

		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	func visit(_: EnumMemberExprSyntax, _: Context) throws -> Doc {
		.empty
	}

	func visit(_ expr: InterpolatedStringExprSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: expr, context: context)

		let segments: Doc = try expr.segments.reduce(.empty) { res, segment in
			switch segment {
			case let .string(string, _):
				res <> text(string)
			case let .expr(interpolatedExpr):
				try res <> text("\\(") <> interpolatedExpr.expr.accept(self, context) <> text(")")
			}
		}

		let result = text(#"""#) <> segments <> text(#"""#)
		return comments.leading <> result <> comments.dangling <> comments.trailing
	}

	public func visit(_ stmt: ForStmtSyntax, _ context: Context) throws -> Doc {
		let comments = commentsStore.get(for: stmt, context: context)

		return try comments.leading
			<> text("for")
			<+> stmt.element.accept(self, context)
			<+> text("in")
			<+> stmt.sequence.accept(self, context)
			<+> stmt.body.accept(self, context)
			<> comments.dangling <> comments.trailing
	}

	public func visit(_ expr: LogicalExprSyntax, _ context: Context) throws -> Doc {
		#warning("Generated by Dev/generate-type.rb")

		return text("TODO")
	}

	// GENERATOR_INSERTION

	// MARK: Helpers

	private func join(_ documents: [Doc], with separator: Doc) -> Doc {
		documents.reduce(.empty) { res, doc in
			res.isEmpty ? doc : res <> separator <> doc
		}
	}

	private func group(_ group: Doc) -> Doc {
		.group(group)
	}

	private func text(_ text: String) -> Doc {
		.text(text)
	}

	private func handleVarLet(_ keyword: String, expr: any VarLetDecl, in context: Context) throws -> Doc {
		let keywordDoc = Doc.text(keyword)
		let nameDoc = Doc.text(expr.name)

		var result = keywordDoc <+> nameDoc

		// Optional type annotation
		if let typeExpr = expr.typeExpr {
			let colonDoc = Doc.text(":")
			let typeAnnotationDoc = try typeExpr.accept(self, context)
			result = result <> colonDoc <+> typeAnnotationDoc
		}

		// Optional initializer
		if let initializer = expr.value {
			let equalsDoc = Doc.text("=")
			let initializerExprDoc = try initializer.accept(self, context)
			result = result <+> equalsDoc <+> initializerExprDoc
		}

		// Combine all parts
		return result
	}

	private func preservingNewlines(_ syntax: [any Syntax], in context: Context) throws -> Doc {
		var lastNode: (any Syntax)? = nil

		return try join(syntax.map {
			var result = Doc.empty

			if preserveNewline($0, last: lastNode) {
				result = .hardline
			}

			result = try result <> $0.accept(self, context.last(lastNode))

			lastNode = $0
			return result
		}, with: .line)
	}

	private func preserveNewline(_ a: any Syntax, last: (any Syntax)?) -> Bool {
		if let last {
			a.location.start.line - last.location.end.line >= 2
		} else {
			false
		}
	}
}
