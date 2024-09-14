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
	struct Context {
		enum ChildTrait: Hashable {
			case hasFunc
		}

		enum Kind {
			case declBlock, stmtBlock, topLevel
		}

		var kind: Kind
		var lastNode: (any Syntax)?
		var childTraits = TraitCollection<ChildTrait>()

		var allowsSingleLineStmtBlock: Bool {
			kind != .declBlock
		}

		func copy() -> Context {
			var copy = self
			copy.childTraits = childTraits.copy()
			return copy
		}

		func `in`(_ kind: Kind) -> Context {
			var copy = self
			copy.kind = kind
			copy.childTraits = childTraits.copy()
			return copy
		}

		func last(_ syntax: (any Syntax)?) -> Context {
			var copy = self
			copy.lastNode = syntax
			return copy
		}
	}

	typealias Value = Doc

	func visit(_ expr: CallExprSyntax, _ context: Context) throws -> Doc {
		let callee = try expr.callee.accept(self, context)
		let args = try expr.args.map { try $0.accept(self, context) }

		return group(
			callee <> text("(") <> .nest(1, .softline <> join(args, with: text(",") <> .line)) <> .softline <> text(")")
		)
	}

	func visit(_ expr: DefExprSyntax, _ context: Context) throws -> Doc {
		let lhs = try expr.receiver.accept(self, context)
		let rhs = try expr.value.accept(self, context)
		return lhs <+> text("=") <+> rhs
	}

	func visit(_ expr: IdentifierExprSyntax, _: Context) throws -> Doc {
		.text(expr.name)
	}

	func visit(_ expr: LiteralExprSyntax, _: Context) throws -> Doc {
		switch expr.value {
		case let .int(int):
			.text("\(int)")
		case let .bool(bool):
			.text("\(bool)")
		case let .string(string):
			.text(#"""# + string + #"""#)
		case .none:
			.text("none")
		}
	}

	func visit(_ expr: VarExprSyntax, _: Context) throws -> Doc {
		.text(expr.name)
	}

	func visit(_ expr: UnaryExprSyntax, _ context: Context) throws -> Doc {
		let op = text("\(expr.op)")
		let expr = try expr.expr.accept(self, context)
		return group(op <> expr)
	}

	func visit(_ expr: BinaryExprSyntax, _ context: Context) throws -> Doc {
		let lhs = try expr.lhs.accept(self, context)
		let op = text("\(expr.op.rawValue)")
		let rhs = try expr.rhs.accept(self, context)

		return group(lhs <+> op <+> rhs)
	}

	func visit(_ expr: IfExprSyntax, _ context: Context) throws -> Doc {
		let condition = try expr.condition.accept(self, context)
		let consequence = try expr.consequence.accept(self, context)
		let alternative = try expr.alternative.accept(self, context)

		return group(
			text("if") <+> condition <+> text("{")
				<> .nest(1, .line <> consequence) <> .line
				<> text("}") <+> text("else") <+> text("{")
				<> .nest(1, .line <> alternative) <> .line
				<> text("}")
		)
	}

	func visit(_ expr: WhileStmtSyntax, _ context: Context) throws -> Doc {
		let condition = try expr.condition.accept(self, context)
		let body = try expr.body.accept(self, context)

		return text("while") <+> condition <+> body
	}

	func visit(_ expr: BlockStmtSyntax, _ context: Context) throws -> Doc {
		let context = context.copy()

		if expr.stmts.isEmpty {
			return text("{}")
		}

		let block = try text("{")
			<> .nest(1, .line <> preservingNewlines(expr.stmts, in: context))
			<> .line
			<> text("}")

		// If there's only one statement, we can let the func be a one-liner
		if expr.stmts.count == 1, context.allowsSingleLineStmtBlock, !context.childTraits.has(.hasFunc) {
			return group(block)
		} else {
			// Otherwise, the body should be split
			return block
		}
	}

	func visit(_ expr: FuncExprSyntax, _ context: Context) throws -> Doc {
		var start = text("func")

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
	}

	func visit(_ expr: ParamsExprSyntax, _ context: Context) throws -> Doc {
		try .group(join(expr.params.map { try $0.accept(self, context) }, with: text(",")))
	}

	func visit(_ expr: ParamSyntax, _ context: Context) throws -> Doc {
		var result = text(expr.name)

		if let type = expr.type {
			result = try result <> text(":") <+> type.accept(self, context)
		}

		return result
	}

	func visit(_ expr: GenericParamsSyntax, _ context: Context) throws -> Doc {
		try .group(
			text("<")
				<> join(expr.params.map { try $0.type.accept(self, context) }, with: text(","))
				<> text(">")
		)
	}

	func visit(_ expr: Argument, _ context: Context) throws -> Doc {
		let value = try expr.value.accept(self, context)

		if let label = expr.label {
			return group(
				text(label.lexeme) <> text(":") <+> value
			)
		} else {
			return value
		}
	}

	func visit(_ expr: StructExprSyntax, _ context: Context) throws -> Doc {
		var result = text("struct") <+> text(expr.name ?? "")

		if !expr.typeParameters.isEmpty {
			result = try result
				<> text("<")
				<> join(expr.typeParameters.map { try $0.accept(self, context) }, with: text(","))
				<> text(">")
		}

		return try result <+> expr.body.accept(self, context)
	}

	func visit(_ expr: DeclBlockSyntax, _ context: Context) throws -> Doc {
		let context = context.in(.declBlock)
		let decls = try preservingNewlines(expr.decls, in: context)

		return text("{")
			<> .nest(1, .line <> decls)
			<> .line
			<> text("}")
	}

	func visit(_ expr: VarDeclSyntax, _ context: Context) throws -> Doc {
		try handleVarLet("var", expr: expr, in: context)
	}

	func visit(_ expr: LetDeclSyntax, _ context: Context) throws -> Doc {
		try handleVarLet("let", expr: expr, in: context)
	}

	func visit(_ expr: ParseErrorSyntax, _: Context) throws -> Doc {
		text(expr.message)
	}

	func visit(_ expr: MemberExprSyntax, _ context: Context) throws -> Doc {
		if let receiver = try expr.receiver?.accept(self, context) {
			group(receiver <> text("." + expr.property))
		} else {
			text("." + expr.property)
		}
	}

	func visit(_ expr: ReturnStmtSyntax, _ context: Context) throws -> Doc {
		if let value = expr.value {
			try text("return") <+> value.accept(self, context)
		} else {
			text("return")
		}
	}

	func visit(_ expr: InitDeclSyntax, _ context: Context) throws -> Doc {
		let start: Doc = context.lastNode == nil ? .empty : .hardline

		return try start <> text("init(")
			<> group(expr.params.accept(self, context))
			<> text(")")
			<+> expr.body.accept(self, context)
	}

	func visit(_ expr: ImportStmtSyntax, _: Context) throws -> Doc {
		text("import") <+> text(expr.module.name)
	}

	func visit(_ expr: TypeExprSyntax, _ context: Context) throws -> Doc {
		if expr.genericParams.isEmpty {
			return text(expr.identifier.lexeme)
		}

		return try text(expr.identifier.lexeme)
			<> group(
				text("<")
					<> join(expr.genericParams.map { try $0.accept(self, context) }, with: text(","))
					<> text(">")
			)
	}

	func visit(_ expr: ExprStmtSyntax, _ context: Context) throws -> Doc {
		try expr.expr.accept(self, context)
	}

	func visit(_ expr: IfStmtSyntax, _ context: Context) throws -> Doc {
		let condition = try expr.condition.accept(self, context)
		let consequence = try expr.consequence.accept(self, context)
		let alternative = try expr.alternative?.accept(self, context)

		if let alternative {
			return text("if") <+> condition <+> consequence <+> text("else") <+> alternative
		} else {
			return text("if") <+> condition <+> consequence
		}
	}

	func visit(_ expr: StructDeclSyntax, _ context: Context) throws -> Doc {
		var result = text("struct") <+> text(expr.name)

		if !expr.typeParameters.isEmpty {
			result = try result
				<> text("<")
				<> join(expr.typeParameters.map { try $0.accept(self, context) }, with: text(","))
				<> text(">")
		}

		return try result <+> expr.body.accept(self, context) <> .line
	}

	func visit(_ expr: ArrayLiteralExprSyntax, _ context: Context) throws -> Doc {
		try group(text("[") <> .nest(1, .softline <> join(expr.exprs.map { try $0.accept(self, context) }, with: text(",") <> .line)) <> .softline <> text("]"))
	}

	func visit(_ expr: SubscriptExprSyntax, _ context: Context) throws -> Doc {
		let receiver = try expr.receiver.accept(self, context)
		let args = try join(expr.args.map { try $0.accept(self, context) }, with: text(","))

		return receiver <> text("[") <> args <> text("]")
	}

	func visit(_ expr: DictionaryLiteralExprSyntax, _ context: Context) throws -> Doc {
		try text("[") <> .line <> .nest(1, join(expr.elements.map { try $0.accept(self, context) }, with: text(",") <> .line)) <> .line <> text("]")
	}

	func visit(_ expr: DictionaryElementExprSyntax, _ context: Context) throws -> Doc {
		try expr.key.accept(self, context) <> text(":") <+> expr.value.accept(self, context) <> .line
	}

	func visit(_: ProtocolDeclSyntax, _: Context) throws -> Doc {
		.empty // TODO:
	}

	func visit(_: ProtocolBodyDeclSyntax, _: Context) throws -> Doc {
		.empty // TODO:
	}

	func visit(_: FuncSignatureDeclSyntax, _: Context) throws -> Doc {
		.empty // TODO:
	}

	func visit(_ expr: EnumDeclSyntax, _ context: Context) throws -> Doc {
		var result = text("enum") <+> text(expr.nameToken.lexeme)

		if !expr.typeParams.isEmpty {
			result = try result
				<> text("<")
				<> join(expr.typeParams.map { try $0.accept(self, context) }, with: text(","))
				<> text(">")
		}

		return try result <+> expr.body.accept(self, context) <> .softline
	}

	func visit(_ expr: EnumCaseDeclSyntax, _ context: Context) throws -> Doc {
		var result = text("case \(expr.nameToken.lexeme)")

		if !expr.attachedTypes.isEmpty {
			result = try result <> text("(") <> join(expr.attachedTypes.map { try $0.accept(self, context) }, with: text(",")) <> text(")")
		}

		return result
	}

	func visit(_ expr: MatchStatementSyntax, _ context: Context) throws -> Doc {
		try text("match") <+> expr.target.accept(self, context) <+> text("{")
			<> .line
			<> join(expr.cases.map { try $0.accept(self, context) }, with: .line)
			<> .line
			<> text("}")
			<> .softline
	}

	func visit(_ expr: CaseStmtSyntax, _ context: Context) throws -> Doc {
		if let pattern = expr.patternSyntax {
			try text("case") <+> pattern.accept(self, context)
				<> text(":")
				<> .line
				<> .nest(1, preservingNewlines(expr.body, in: context))
		} else {
			try text("else") <> .line <> join(expr.body.map { try $0.accept(self, context) }, with: .line)
		}
	}

	func visit(_: EnumMemberExprSyntax, _: Context) throws -> Doc {
		.empty
	}

	func visit(_ expr: InterpolatedStringExprSyntax, _ context: Context) throws -> Doc {
		let segments: Doc = try expr.segments.reduce(.empty) { res, segment in
			switch segment {
			case let .string(string, _):
				res <> text(string)
			case let .expr(interpolatedExpr):
				try res <> interpolatedExpr.expr.accept(self, context)
			}
		}

		return text(#"""#) <> segments <> text(#"""#)
	}

	// MARK: Helpers

	private func join(_ documents: [Doc], with separator: Doc) -> Doc {
		documents.reduce(.empty) { res, doc in
			res == .empty ? doc : res <> separator <> doc
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
