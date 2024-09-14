//
//  Formatter.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/13/24.
//
infix operator <>: AdditionPrecedence
infix operator <|>: AdditionPrecedence
infix operator <+>: AdditionPrecedence

indirect enum Document: Equatable {
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
	case nest(Int, Document)

	// Two documents that need to be concatenated
	case concat(Document, Document)

	// A choice between two layouts for a document
	case group(Document)

	// Return a concat of these two documents
	static func <>(lhs: Document, rhs: Document) -> Document {
		.concat(lhs, rhs)
	}

	// Return a concat of these two documents with a space
	static func <+>(lhs: Document, rhs: Document) -> Document {
		lhs <> .text(" ") <> rhs
	}
}

public struct Formatter {
	let ast: [any Syntax]

	public init(input: SourceFile) {
		do {
			self.ast = try Parser.parse(input)
		} catch {
			self.ast = []
		}
	}

	public func format(width: Int = 84) throws -> String {
		let visitor = FormatterVisitor()
		let context = FormatterVisitor.Context()

		return try ast.map {
			try format(
				document: $0.accept(visitor, context),
				width: width
			)
		}.joined(separator: "\n")
	}

	func format(document: Document, width: Int) -> String {
		var output = ""

		var queue: [(Int, Document)] = [(0, document)]

		while !queue.isEmpty {
			let (indent, currentDoc) = queue.removeFirst()
			switch currentDoc {
			case .empty:
				continue
			case .text(let str):
				output += str
			case .line, .softline, .hardline:
				output += "\n" + String(repeating: "\t", count: indent)
			case .concat(let left, let right):
				queue.insert((indent, right), at: 0)
				queue.insert((indent, left), at: 0)
			case .nest(let ind, let nestedDoc):
				queue.insert((indent + ind, nestedDoc), at: 0)
			case .group(let groupedDoc):
				let flat = flatten(groupedDoc)
				if fits(width - output.count % width, doc: flat) {
					queue.insert((indent, flat), at: 0)
				} else {
					queue.insert((indent, groupedDoc), at: 0)
				}
			}
		}
		return output
	}

	func flatten(_ doc: Document) -> Document {
		switch doc {
		case .empty, .text:
			return doc
		case .hardline:
			return .hardline
		case .softline:
			return .text("")
		case .line:
			return .text(" ")
		case .concat(let left, let right):
			return .concat(flatten(left), flatten(right))
		case .nest(let indent, let nestedDoc):
			return .nest(indent, flatten(nestedDoc))
		case .group(let groupedDoc):
			return flatten(groupedDoc)
		}
	}

	func fits(_ remainingWidth: Int, doc: Document) -> Bool {
		var width = remainingWidth
		var queue: [Document] = [doc]

		while width >= 0 && !queue.isEmpty {
			let currentDoc = queue.removeFirst()
			switch currentDoc {
			case .empty:
				continue
			case .text(let str):
				width -= str.count
			case .line:
				return true
			case .softline:
				return true
			case .hardline:
				return true
			case .concat(let left, let right):
				queue.insert(right, at: 0)
				queue.insert(left, at: 0)
			case .nest(_, let nestedDoc):
				queue.insert(nestedDoc, at: 0)
			case .group(let groupedDoc):
				queue.insert(groupedDoc, at: 0)
			}
		}
		return width >= 0
	}
}

struct FormatterVisitor: Visitor {
	struct Context {}
	typealias Value = Document

	func visit(_ expr: CallExprSyntax, _ context: Context) throws -> Document {
		let callee = try expr.callee.accept(self, context)
		let args = try expr.args.map { try $0.accept(self, context) }

		return group(
			callee <> text("(") <> .nest(1, .softline <> join(args, with: text(",") <> .line)) <> .softline <> text(")")
		)
	}

	func visit(_ expr: DefExprSyntax, _ context: Context) throws -> Document {
		let lhs = try expr.receiver.accept(self, context)
		let rhs = try expr.value.accept(self, context)
		return lhs <+> text("=") <+> rhs
	}

	func visit(_ expr: IdentifierExprSyntax, _ context: Context) throws -> Document {
		.text(expr.name)
	}

	func visit(_ expr: LiteralExprSyntax, _ context: Context) throws -> Document {
		switch expr.value {
		case .int(let int):
			.text("\(int)")
		case .bool(let bool):
			.text("\(bool)")
		case .string(let string):
			.text(#"""# + string + #"""#)
		case .none:
			.text("none")
		}
	}

	func visit(_ expr: VarExprSyntax, _ context: Context) throws -> Document {
		.text(expr.name)
	}

	func visit(_ expr: UnaryExprSyntax, _ context: Context) throws -> Document {
		let op = text("\(expr.op)")
		let expr = try expr.expr.accept(self, context)
		return group(op <> expr)
	}

	func visit(_ expr: BinaryExprSyntax, _ context: Context) throws -> Document {
		let lhs = try expr.lhs.accept(self, context)
		let op = text("\(expr.op.rawValue)")
		let rhs = try expr.rhs.accept(self, context)

		return group(lhs <+> op <+> rhs)
	}

	func visit(_ expr: IfExprSyntax, _ context: Context) throws -> Document {
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

	func visit(_ expr: WhileStmtSyntax, _ context: Context) throws -> Document {
		let condition = try expr.condition.accept(self, context)
		let body = try expr.accept(self, context)

		return group(
			text("while") <+> condition <+> text("{")
				<> .nest(1, .line <> body)
				<> .line
				<> text("}")
		)
	}

	func visit(_ expr: BlockStmtSyntax, _ context: Context) throws -> Document {
		let block = try text("{")
			<> .nest(1, .line <> join(expr.stmts.map { try $0.accept(self, context) }, with: .line))
			<> .line
			<> text("}")

		// If there's only one statement, we can let the func be a one-liner
		if expr.stmts.count == 1 {
			return group(block)
		} else {
			// Otherwise, the body should be split
			return block
		}
	}

	func visit(_ expr: FuncExprSyntax, _ context: Context) throws -> Document {
		var start = text("func")

		if let name = expr.name?.lexeme {
			start = start <+> text(name)
		}

		let params = try expr.params.accept(self, context)
		let body = try expr.body.accept(self, context)

		return start
			<> text("(")
			<> params
			<> text(")")
			<+> body
	}

	func visit(_ expr: ParamsExprSyntax, _ context: Context) throws -> Document {
		try .group(join(expr.params.map { try $0.accept(self, context) }, with: text(",")))
	}

	func visit(_ expr: ParamSyntax, _ context: Context) throws -> Document {
		var result = text(expr.name)

		if let type = expr.type {
			result = try result <> text(":") <+> type.accept(self, context)
		}

		return result
	}

	func visit(_ expr: GenericParamsSyntax, _ context: Context) throws -> Document {
		try .group(
			text("<")
				<> join(expr.params.map { try $0.type.accept(self, context) }, with: text(","))
				<> text(">")
		)
	}

	func visit(_ expr: Argument, _ context: Context) throws -> Document {
		let value = try expr.value.accept(self, context)

		if let label = expr.label {
			return group(
				text(label.lexeme) <> text(":") <+> value
			)
		} else {
			return value
		}
	}

	func visit(_ expr: StructExprSyntax, _ context: Context) throws -> Document {
		.empty // TODO:
	}

	func visit(_ expr: DeclBlockSyntax, _ context: Context) throws -> Document {
		return try group(
			text("{")
				<> .nest(1, .line <> join(expr.decls.map { try $0.accept(self, context) }, with: .line))
				<> .line
				<> text("}")
		)
	}

	func visit(_ expr: VarDeclSyntax, _ context: Context) throws -> Document {
		try handleVarLet("var", expr: expr, in: context)
	}

	func visit(_ expr: LetDeclSyntax, _ context: Context) throws -> Document {
		try handleVarLet("let", expr: expr, in: context)
	}

	func visit(_ expr: ParseErrorSyntax, _ context: Context) throws -> Document {
		text(expr.message)
	}

	func visit(_ expr: MemberExprSyntax, _ context: Context) throws -> Document {
		if let receiver = try expr.receiver?.accept(self, context) {
			return group(receiver <> text("." + expr.property))
		} else {
			return text("." + expr.property)
		}
	}

	func visit(_ expr: ReturnStmtSyntax, _ context: Context) throws -> Document {
		if let value = expr.value {
			return try text("return") <+> value.accept(self, context)
		} else {
			return text("return")
		}
	}

	func visit(_ expr: InitDeclSyntax, _ context: Context) throws -> Document {
		return try text("init(")
			<> group(expr.params.accept(self, context))
			<> text(")")
			<+> expr.body.accept(self, context)
	}

	func visit(_ expr: ImportStmtSyntax, _ context: Context) throws -> Document {
		text("import") <+> text(expr.module.name)
	}

	func visit(_ expr: TypeExprSyntax, _ context: Context) throws -> Document {
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

	func visit(_ expr: ExprStmtSyntax, _ context: Context) throws -> Document {
		try expr.expr.accept(self, context)
	}

	func visit(_ expr: IfStmtSyntax, _ context: Context) throws -> Document {
		let condition = try expr.condition.accept(self, context)
		let consequence = try expr.consequence.accept(self, context)
		let alternative = try expr.alternative?.accept(self, context)

		if let alternative {
			return group(
				text("if") <+> condition <+> text("{")
					<> .nest(1, .line <> consequence) <> .line
					<> text("}") <+> text("else") <+> text("{")
					<> .nest(1, .line <> alternative) <> .line
					<> text("}")
			)
		} else {
			return group(
				text("if") <+> condition <+> text("{")
					<> .nest(1, .line <> consequence) <> .line
					<> text("}")
			)
		}
	}

	func visit(_ expr: StructDeclSyntax, _ context: Context) throws -> Document {
		var result = text("struct") <+> text(expr.name)

		if !expr.typeParameters.isEmpty {
			result = try result
				<> text("<")
				<> join(expr.typeParameters.map { try $0.accept(self, context) }, with: text(","))
				<> text(">")
		}

		return try result <+> expr.body.accept(self, context)
	}

	func visit(_ expr: ArrayLiteralExprSyntax, _ context: Context) throws -> Document {
		try group(text("[") <> .nest(1, .softline <> join(expr.exprs.map { try $0.accept(self, context) }, with: text(",") <> .line)) <> .softline <> text("]"))
	}

	func visit(_ expr: SubscriptExprSyntax, _ context: Context) throws -> Document {
		let receiver = try expr.receiver.accept(self, context)
		let args = try join(expr.args.map { try $0.accept(self, context) }, with: text(","))

		return receiver <> text("[") <> args <> text("]")
	}

	func visit(_ expr: DictionaryLiteralExprSyntax, _ context: Context) throws -> Document {
		try text("[") <> .line <> .nest(1, join(expr.elements.map { try $0.accept(self, context) }, with: text(",") <> .line)) <> .line <> text("]")
	}

	func visit(_ expr: DictionaryElementExprSyntax, _ context: Context) throws -> Document {
		try expr.key.accept(self, context) <> text(":") <+> expr.value.accept(self, context) <> .line
	}

	func visit(_ expr: ProtocolDeclSyntax, _ context: Context) throws -> Document {
		.empty // TODO:
	}

	func visit(_ expr: ProtocolBodyDeclSyntax, _ context: Context) throws -> Document {
		.empty // TODO:
	}

	func visit(_ expr: FuncSignatureDeclSyntax, _ context: Context) throws -> Document {
		.empty // TODO:
	}

	func visit(_ expr: EnumDeclSyntax, _ context: Context) throws -> Document {
		var result = text("enum") <+> text(expr.nameToken.lexeme)

		if !expr.typeParams.isEmpty {
			result = try result
				<> text("<")
				<> join(expr.typeParams.map { try $0.accept(self, context) }, with: text(","))
				<> text(">")
		}

		return try result <+> expr.body.accept(self, context)
	}

	func visit(_ expr: EnumCaseDeclSyntax, _ context: Context) throws -> Document {
		var result = text("case \(expr.nameToken.lexeme)")

		if !expr.attachedTypes.isEmpty {
			result = try result <> text("(") <> join(expr.attachedTypes.map { try $0.accept(self, context) }, with: text(",")) <> text(")")
		}

		return result
	}

	func visit(_ expr: MatchStatementSyntax, _ context: Context) throws -> Document {
		return try group(
			text("match") <> expr.target.accept(self, context) <+> text("{") <> .line
				<> .nest(1, join(expr.cases.map { try $0.accept(self, context) }, with: .line))
				<> .line
				<> text("}")
		)
	}

	func visit(_ expr: CaseStmtSyntax, _ context: Context) throws -> Document {
		if let pattern = expr.patternSyntax {
			return try text("case") <+> pattern.accept(self, context) <> text(":")
				<> group(
					join(expr.body.map { try $0.accept(self, context) }, with: .line)
				)
		} else {
			return try text("else") <> .line <> join(expr.body.map { try $0.accept(self, context) }, with: .line)
		}
	}

	func visit(_ expr: EnumMemberExprSyntax, _ context: Context) throws -> Document {
		.empty
	}

	func visit(_ expr: InterpolatedStringExprSyntax, _ context: Context) throws -> Document {
		let segments: Document = try expr.segments.reduce(.empty) { res, segment in
			switch segment {
			case .string(let string, _):
				return res <> text(string)
			case .expr(let interpolatedExpr):
				return try res <> interpolatedExpr.expr.accept(self, context)
			}
		}

		return text(#"""#) <> segments <> text(#"""#)
	}

	// MARK: Helpers

	private func join(_ documents: [Document], with separator: Document) -> Document {
		documents.reduce(.empty) { res, doc in
			res == .empty ? doc : res <> separator <> doc
		}
	}

	private func group(_ group: Document) -> Document {
		.group(group)
	}

	private func text(_ text: String) -> Document {
		.text(text)
	}

	private func handleVarLet(_ keyword: String, expr: any VarLetDecl, in context: Context) throws -> Document {
		let keywordDoc = Document.text(keyword)
		let nameDoc = Document.text(expr.name)

		// Optional type annotation
		let typeDoc: Document
		if let typeExpr = expr.typeExpr {
			let colonDoc = Document.text(":")
			let typeAnnotationDoc = try typeExpr.accept(self, context)
			typeDoc = colonDoc <+> typeAnnotationDoc
		} else {
			typeDoc = .empty
		}

		// Optional initializer
		let initializerDoc: Document
		if let initializer = expr.value {
			let equalsDoc = Document.text("=")
			let initializerExprDoc = try initializer.accept(self, context)
			initializerDoc = equalsDoc <+> initializerExprDoc
		} else {
			initializerDoc = .empty
		}

		// Combine all parts
		return Document.group(
			keywordDoc <+> nameDoc <> typeDoc <> initializerDoc
		)
	}
}
