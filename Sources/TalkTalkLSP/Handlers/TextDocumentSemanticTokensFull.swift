//
//  TextDocumentSemanticTokensFull.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import Foundation
import TalkTalkAnalysis
import TalkTalkSyntax

struct TextDocumentSemanticTokensFull {
	var request: Request

	func handle(_ handler: Server) async {
		let params = request.params as! TextDocumentSemanticTokensFullRequest

		guard let source = await handler.sources[params.textDocument.uri] else {
			Log.error("no source for \(params.textDocument.uri)")
			return
		}

		var tokens: [RawSemanticToken]

		do {
			// TODO: use module environment
			let parsed = try await SourceFileAnalyzer.analyze(
				Parser.parse(SourceFile(path: params.textDocument.uri, text: source.text), allowErrors: true),
				in: Environment(symbolGenerator: .init(moduleName: "", parent: nil))
			)
			let visitor = SemanticTokensVisitor()
			tokens = try parsed.flatMap { parsed in try parsed.accept(visitor, .topLevel) }
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
					startChar: index.utf16Offset(in: text),
					length: text.count - index.utf16Offset(in: text),
					tokenType: .comment,
					modifiers: []
				))
			}
		}

		let relativeTokens = RelativeSemanticToken.generate(from: tokens)
		let response = TextDocumentSemanticTokens(data: Array(relativeTokens.map(\.serialized).joined()))
		await handler.respond(to: request.id, with: response)
	}
}

struct SemanticTokensVisitor: Visitor {
	enum Context {
		case topLevel, `struct`, condition, callee, initializer
	}

	typealias Value = [RawSemanticToken]

	func make(_ kind: SemanticTokenTypes, from token: Token) -> RawSemanticToken {
		RawSemanticToken(lexeme: token.lexeme, line: token.line, startChar: token.column, length: token.length, tokenType: kind, modifiers: [])
	}

	func visit(_ expr: any ExprStmt, _ context: Context) throws -> [RawSemanticToken] {
		try expr.expr.accept(self, context)
	}

	func visit(_ expr: any TypeExpr, _: Context) throws -> [RawSemanticToken] {
		[make(.type, from: expr.identifier)]
	}

	func visit(_ expr: CallExpr, _ context: Context) throws -> [RawSemanticToken] {
		var results = try expr.callee.accept(self, .callee)
		try results.append(contentsOf: expr.args.flatMap { try $0.value.accept(self, context) })
		return results
	}

	public func visit(_ expr: any ImportStmt, _: Context) throws -> [RawSemanticToken] {
		[make(.keyword, from: expr.token)]
	}

	func visit(_ expr: DefExpr, _ context: Context) throws -> [RawSemanticToken] {
		var result = try expr.receiver.accept(self, context)
		try result.append(contentsOf: expr.value.accept(self, context))

		return result
	}

	func visit(_ expr: CallArgument, _ context: Context) throws -> [RawSemanticToken] {
		var result: [RawSemanticToken] = []
		if let label = expr.label {
			result.append(make(.parameter, from: label))
		}

		try result.append(contentsOf: expr.value.accept(self, context))

		return result
	}

	func visit(_: ParseError, _: Context) throws -> [RawSemanticToken] {
		[]
	}

	func visit(_: any TalkTalkSyntax.Param, _: Context) throws -> [RawSemanticToken] {
		[]
	}

	func visit(_: any GenericParams, _: Context) throws -> [RawSemanticToken] {
		[]
	}

	func visit(_ expr: LiteralExpr, _: Context) throws -> [RawSemanticToken] {
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
				startChar: expr.location.start.column,
				length: expr.location.start.length,
				tokenType: kind,
				modifiers: []
			),
		]
	}

	func visit(_ expr: VarExpr, _: Context) throws -> [RawSemanticToken] {
		[make(.variable, from: expr.token)]
	}

	func visit(_ expr: BinaryExpr, _ context: Context) throws -> [RawSemanticToken] {
		var result: [RawSemanticToken] = []
		try result.append(contentsOf: expr.lhs.accept(self, context))
		try result.append(contentsOf: expr.rhs.accept(self, context))
		return result
	}

	func visit(_ expr: UnaryExpr, _ context: Context) throws -> [RawSemanticToken] {
		try expr.expr.accept(self, context)
	}

	func visit(_ expr: IfExpr, _ context: Context) throws -> [RawSemanticToken] {
		var results = [make(.keyword, from: expr.ifToken)]

		try results.append(contentsOf: expr.condition.accept(self, context))
		try results.append(contentsOf: expr.consequence.accept(self, context))

		if let elseToken = expr.elseToken {
			results.append(make(.keyword, from: elseToken))
		}

		try results.append(contentsOf: expr.alternative.accept(self, context))

		return results
	}

	func visit(_ expr: FuncExpr, _ context: Context) throws -> [RawSemanticToken] {
		var results = [make(.keyword, from: expr.funcToken)]

		if let name = expr.name {
			results.append(make(context == .struct ? .method : .function, from: name))
		}

		try results.append(contentsOf: expr.params.accept(self, context))
		try results.append(contentsOf: expr.body.accept(self, context))

		return results
	}

	func visit(_ expr: BlockStmt, _ context: Context) throws -> [RawSemanticToken] {
		var result: [RawSemanticToken] = []
		for expr in expr.stmts {
			try result.append(contentsOf: expr.accept(self, context))
		}
		return result
	}

	func visit(_ expr: WhileStmt, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.whileToken)]
		try result.append(contentsOf: expr.condition.accept(self, .condition))
		try result.append(contentsOf: expr.body.accept(self, context))

		return result
	}

	func visit(_ expr: ParamsExpr, _: Context) throws -> [RawSemanticToken] {
		expr.params.map {
			make(.parameter, from: $0.location.start)
		}
	}

	func visit(_ expr: ReturnStmt, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.returnToken)]

		if let value = expr.value {
			try result.append(contentsOf: value.accept(self, context))
		}

		return result
	}

	func visit(_: IdentifierExpr, _: Context) throws -> [RawSemanticToken] {
		[]
	}

	func visit(_ expr: MemberExpr, _ context: Context) throws -> [RawSemanticToken] {
		var result = try expr.receiver.accept(self, context)
		result.append(make(.property, from: expr.propertyToken))
		return result
	}

	func visit(_ expr: DeclBlock, _ context: Context) throws -> [RawSemanticToken] {
		var result: [RawSemanticToken] = []

		for expr in expr.decls {
			try result.append(contentsOf: expr.accept(self, context))
		}

		return result
	}

	func visit(_ expr: StructDecl, _: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.structToken)]
		try result.append(contentsOf: expr.body.accept(self, .struct))
		return result
	}

	func visit(_ expr: any InitDecl, _: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.initToken)]
		try result.append(contentsOf: visit(expr.parameters, .initializer))
		try result.append(contentsOf: expr.body.accept(self, .initializer))
		return result
	}

	func visit(_ expr: VarDecl, _ context: Context) throws -> [RawSemanticToken] {
		var result = [
			make(.keyword, from: expr.token),
		]

		if let token = expr.typeDeclToken {
			result.append(make(.type, from: token))
		}

		if let value = expr.value {
			try result.append(contentsOf: value.accept(self, context))
		}

		return result
	}

	func visit(_ expr: LetDecl, _ context: Context) throws -> [RawSemanticToken] {
		var result = [
			make(.keyword, from: expr.token),
		]

		if let token = expr.typeDeclToken {
			result.append(make(.type, from: token))
		}

		if let value = expr.value {
			try result.append(contentsOf: value.accept(self, context))
		}

		return result
	}

	func visit(_ expr: any IfStmt, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.ifToken)]
		try result.append(contentsOf: expr.condition.accept(self, context))
		try result.append(contentsOf: expr.consequence.accept(self, context))

		if let alternative = expr.alternative, let elseToken = expr.elseToken {
			result.append(make(.keyword, from: elseToken))
			try result.append(contentsOf: alternative.accept(self, context))
		}

		return result
	}

	func visit(_ expr: any StructExpr, _: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.structToken)]
		try result.append(contentsOf: expr.body.accept(self, .struct))
		return result
	}

	func visit(_ expr: any ArrayLiteralExpr, _ context: Context) throws -> [RawSemanticToken] {
		try expr.children.flatMap { try $0.accept(self, context) }
	}

	func visit(_ expr: any SubscriptExpr, _ context: Context) throws -> [RawSemanticToken] {
		try expr.args.flatMap { try $0.accept(self, context) }
	}

	func visit(_ expr: any AssignmentStmt, _ context: Context) throws -> [RawSemanticToken] {
		return []
	}


	// GENERATOR_INSERTION
}
