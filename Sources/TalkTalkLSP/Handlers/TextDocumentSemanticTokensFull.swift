//
//  TextDocumentSemanticTokensFull.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import Foundation
import TalkTalkAnalysis
import TalkTalkSyntax
import TypeChecker

struct TextDocumentSemanticTokensFull {
	var request: Request

	func handle(_ server: Server) async {
		guard let params = request.params as? TextDocumentSemanticTokensFullRequest else {
			Log.error("Could not parse TextDocumentSemanticTokensFullRequest params")
			return
		}

		guard let source = await server.sources[params.textDocument.uri] else {
			Log.error("no source for \(params.textDocument.uri)")
			return
		}

		var tokens: [RawSemanticToken]

		do {
			// TODO: use module environment
			let parsed = try await Parser.parse(SourceFile(path: params.textDocument.uri, text: source.text), allowErrors: true)
			let visitor = SemanticTokensVisitor()
			tokens = try parsed.flatMap { parsed in try parsed.accept(visitor, .topLevel) }
			Log.info("Parsed \(tokens.count) tokens")
		} catch {
			Log.error("error parsing semantic tokens: \(error)")
			return
		}

		// Add in comment tokens since we lost those during parsing
		for (line, text) in await source.text.components(separatedBy: .newlines).enumerated() {
			if let index = text.firstIndex(of: "/"),
			   text[text.index(index, offsetBy: 1)] == "/"
			{
				tokens.append(.init(
					lexeme: "<comment>",
					line: line,
					position: index.utf16Offset(in: text),
					startChar: index.utf16Offset(in: text),
					length: text.count - index.utf16Offset(in: text),
					tokenType: .comment,
					modifiers: []
				))
			}
		}

		let relativeTokens = RelativeSemanticToken.generate(from: tokens)
		let response = TextDocumentSemanticTokens(data: Array(relativeTokens.map(\.serialized).joined()))
		await server.respond(to: request.id, with: response)
	}
}

public struct SemanticTokensVisitor: Visitor {
	public enum Context {
		case topLevel, `struct`, condition, callee, initializer
	}

	public init() {}

	public typealias Value = [RawSemanticToken]

	func make(_ kind: SemanticTokenTypes, from token: Token) -> RawSemanticToken {
		RawSemanticToken(
			lexeme: token.lexeme,
			line: token.line,
			position: token.start,
			startChar: token.column,
			length: token.length,
			tokenType: kind,
			modifiers: []
		)
	}

	public func visit(_ expr: ExprStmtSyntax, _ context: Context) throws -> [RawSemanticToken] {
		try expr.expr.accept(self, context)
	}

	public func visit(_ expr: TypeExprSyntax, _: Context) throws -> [RawSemanticToken] {
		[make(.type, from: expr.identifier)]
	}

	public func visit(_ expr: CallExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var results = try expr.callee.accept(self, .callee)
		try results.append(contentsOf: expr.args.flatMap { try $0.value.accept(self, context) })
		return results
	}

	public func visit(_ expr: ImportStmtSyntax, _: Context) throws -> [RawSemanticToken] {
		[make(.keyword, from: expr.token)]
	}

	public func visit(_ expr: DefExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result = try expr.receiver.accept(self, context)
		try result.append(contentsOf: expr.value.accept(self, context))

		return result
	}

	public func visit(_ expr: Argument, _ context: Context) throws -> [RawSemanticToken] {
		var result: [RawSemanticToken] = []
		if let label = expr.label {
			result.append(make(.parameter, from: label))
		}

		try result.append(contentsOf: expr.value.accept(self, context))

		return result
	}

	public func visit(_: ParseErrorSyntax, _: Context) throws -> [RawSemanticToken] {
		[]
	}

	public func visit(_: ParamSyntax, _: Context) throws -> [RawSemanticToken] {
		[]
	}

	public func visit(_: GenericParamsSyntax, _: Context) throws -> [RawSemanticToken] {
		[]
	}

	public func visit(_ expr: LiteralExprSyntax, _: Context) throws -> [RawSemanticToken] {
		let kind: SemanticTokenTypes

		switch expr.value {
		case .int:
			kind = .number
		case .bool:
			kind = .keyword
		case .string:
			kind = .string
		case .none:
			return []
		}

		return [
			RawSemanticToken(
				lexeme: expr.location.start.lexeme,
				line: Int(expr.location.line),
				position: expr.location.start.start,
				startChar: expr.location.start.column,
				length: expr.location.start.length,
				tokenType: kind,
				modifiers: []
			),
		]
	}

	public func visit(_ expr: VarExprSyntax, _: Context) throws -> [RawSemanticToken] {
		[make(.variable, from: expr.token)]
	}

	public func visit(_ expr: BinaryExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result: [RawSemanticToken] = []
		try result.append(contentsOf: expr.lhs.accept(self, context))
		try result.append(contentsOf: expr.rhs.accept(self, context))
		return result
	}

	public func visit(_ expr: UnaryExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		try expr.expr.accept(self, context)
	}

	public func visit(_ expr: IfExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var results = [make(.keyword, from: expr.ifToken)]

		try results.append(contentsOf: expr.condition.accept(self, context))
		try results.append(contentsOf: expr.consequence.accept(self, context))

		if let elseToken = expr.elseToken {
			results.append(make(.keyword, from: elseToken))
		}

		try results.append(contentsOf: expr.alternative.accept(self, context))

		return results
	}

	public func visit(_ expr: FuncExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var results = [make(.keyword, from: expr.funcToken)]

		if let name = expr.name {
			results.append(make(context == .struct ? .method : .function, from: name))
		}

		try results.append(contentsOf: expr.params.accept(self, context))
		try results.append(contentsOf: expr.body.accept(self, context))

		return results
	}

	public func visit(_ expr: BlockStmtSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result: [RawSemanticToken] = []
		for expr in expr.stmts {
			try result.append(contentsOf: expr.accept(self, context))
		}
		return result
	}

	public func visit(_ expr: WhileStmtSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.whileToken)]
		try result.append(contentsOf: expr.condition.accept(self, .condition))
		try result.append(contentsOf: expr.body.accept(self, context))

		return result
	}

	public func visit(_ expr: ParamsExprSyntax, _: Context) throws -> [RawSemanticToken] {
		expr.params.map {
			make(.parameter, from: $0.location.start)
		}
	}

	public func visit(_ expr: ReturnStmtSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.returnToken)]

		if let value = expr.value {
			try result.append(contentsOf: value.accept(self, context))
		}

		return result
	}

	public func visit(_: IdentifierExprSyntax, _: Context) throws -> [RawSemanticToken] {
		[]
	}

	public func visit(_ expr: MemberExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result = try expr.receiver?.accept(self, context) ?? []
		result.append(make(.property, from: expr.propertyToken))
		return result
	}

	public func visit(_ expr: DeclBlockSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result: [RawSemanticToken] = []

		for expr in expr.decls {
			try result.append(contentsOf: expr.accept(self, context))
		}

		return result
	}

	public func visit(_ expr: StructDeclSyntax, _: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.structToken)]
		result.append(make(.type, from: expr.nameToken))
		try result.append(contentsOf: expr.body.accept(self, .struct))
		return result
	}

	public func visit(_ expr: InitDeclSyntax, _: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.initToken)]
		try result.append(contentsOf: visit(expr.params.cast(ParamsExprSyntax.self), .initializer))
		try result.append(contentsOf: expr.body.accept(self, .initializer))
		return result
	}

	public func visit(_ expr: VarDeclSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result = [
			make(.keyword, from: expr.token),
		]

		if let value = expr.value {
			try result.append(contentsOf: value.accept(self, context))
		}

		return result
	}

	public func visit(_ expr: LetDeclSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result = [
			make(.keyword, from: expr.token),
		]

		if let value = expr.value {
			try result.append(contentsOf: value.accept(self, context))
		}

		return result
	}

	public func visit(_ expr: IfStmtSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.ifToken)]
		try result.append(contentsOf: expr.condition.accept(self, context))
		try result.append(contentsOf: expr.consequence.accept(self, context))

		if let alternative = expr.alternative, let elseToken = expr.elseToken {
			result.append(make(.keyword, from: elseToken))
			try result.append(contentsOf: alternative.accept(self, context))
		}

		return result
	}

	public func visit(_ expr: StructExprSyntax, _: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.structToken)]
		try result.append(contentsOf: expr.body.accept(self, .struct))
		return result
	}

	public func visit(_ expr: ArrayLiteralExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		try expr.children.flatMap { try $0.accept(self, context) }
	}

	public func visit(_ expr: SubscriptExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		try expr.args.flatMap { try $0.accept(self, context) }
	}

	public func visit(_ expr: DictionaryLiteralExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		try expr.elements.flatMap { try $0.accept(self, context) }
	}

	public func visit(_ expr: DictionaryElementExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var results = try expr.key.accept(self, context)
		try results.append(contentsOf: expr.value.accept(self, context))
		return results
	}

	public func visit(_ expr: ProtocolDeclSyntax, _ context: Context) throws -> [RawSemanticToken] {
		return [make(.keyword, from: expr.keywordToken)]
	}

	public func visit(_ expr: ProtocolBodyDeclSyntax, _ context: Context) throws -> [RawSemanticToken] {
		return try expr.decls.flatMap { try $0.accept(self, context) }
	}

	public func visit(_ expr: FuncSignatureDeclSyntax, _ context: Context) throws -> [RawSemanticToken] {
		return [make(.keyword, from: expr.funcToken)]
	}

	public func visit(_ expr: EnumDeclSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.enumToken)]

		for child in expr.children {
			result.append(contentsOf: try child.accept(self, context))
		}

		return result
	}

	public func visit(_ expr: EnumCaseDeclSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.caseToken), make(.property, from: expr.nameToken)]

		for type in expr.attachedTypes {
			try result.append(contentsOf: type.accept(self, context))
		}

		return result
	}

	public func visit(_ expr: MatchStatementSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.matchToken)]

		for kase in expr.cases {
			try result.append(contentsOf: kase.accept(self, context))
		}

		return result
	}

	public func visit(_ expr: CaseStmtSyntax, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.caseToken)]

		if let pattern = expr.patternSyntax {
			try result.append(contentsOf: pattern.accept(self, context))
		}

		for stmt in expr.body {
			try result.append(contentsOf: stmt.accept(self, context))
		}

		return result
	}

	public func visit(_ expr: EnumMemberExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		try expr.children.flatMap { try $0.accept(self, context) }
	}

	public func visit(_ expr: InterpolatedStringExprSyntax, _ context: Context) throws -> [RawSemanticToken] {
		#warning("TODO")
		return []
	}

	// GENERATOR_INSERTION
}
