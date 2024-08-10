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

	func handle(_ handler: inout Server) {
		let params = request.params as! TextDocumentSemanticTokensFullRequest

		guard let source = handler.sources[params.textDocument.uri] else {
			Log.error("no source for \(params.textDocument.uri)")
			return
		}

		let tokens: [RawSemanticToken]
		do {
			// TODO: use module environment
			let parsed = try SourceFileAnalyzer.analyze(Parser.parse(source.text), in: Environment())
			let visitor = SemanticTokensVisitor()
			tokens = try parsed.flatMap { parsed in try parsed.accept(visitor, .topLevel) }
		} catch {
			Log.error("error parsing semantic tokens: \(error)")
			return
		}

		let relativeTokens = RelativeSemanticToken.generate(from: tokens)
		let response = TextDocumentSemanticTokens(data: Array(relativeTokens.map(\.serialized).joined()))
		handler.respond(to: request.id, with: response)
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

	func visit(_ expr: CallExpr, _ context: Context) throws -> [RawSemanticToken] {
		var results = try expr.callee.accept(self, .callee)
		try results.append(contentsOf: expr.args.flatMap { try $0.value.accept(self, context) })
		return results
	}

	public func visit(_ expr: any ImportStmt, _ context: Context) throws -> [RawSemanticToken] {
	[make(.keyword, from: expr.token)]
}

	func visit(_ expr: DefExpr, _ context: Context) throws -> [RawSemanticToken] {
		var result = try expr.receiver.accept(self, context)
		try result.append(contentsOf:	expr.value.accept(self, context))

		return result
	}

	func visit(_ expr: ErrorSyntax, _ context: Context) throws -> [RawSemanticToken] {
		[]
	}

	func visit(_ expr: any TalkTalkSyntax.Param, _ context: Context) throws -> [RawSemanticToken] {
		[]
	}

	func visit(_ expr: LiteralExpr, _ context: Context) throws -> [RawSemanticToken] {
		let kind: SemanticTokenTypes

		switch expr.value {
		case .int(_):
			kind = .number
		case .bool(_):
			kind = .keyword
		case .string(_):
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
			)
		]
	}

	func visit(_ expr: VarExpr, _ context: Context) throws -> [RawSemanticToken] {
		[make(.variable, from: expr.token)]
	}

	func visit(_ expr: BinaryExpr, _ context: Context) throws -> [RawSemanticToken] {
		var result: [RawSemanticToken] = []
		try result.append(contentsOf: expr.lhs.accept(self, context))
		try result.append(contentsOf: expr.rhs.accept(self, context))
		return result
	}

	func visit(_ expr: UnaryExpr, _ context: Context) throws -> [RawSemanticToken] {
		return try expr.expr.accept(self, context)
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

	func visit(_ expr: BlockExpr, _ context: Context) throws -> [RawSemanticToken] {
		var result: [RawSemanticToken] = []
		for expr in expr.exprs {
			try result.append(contentsOf: expr.accept(self, context))
		}
		return result
	}

	func visit(_ expr: WhileExpr, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.whileToken)]
		try result.append(contentsOf: expr.condition.accept(self, .condition))
		try result.append(contentsOf: expr.body.accept(self, context))

		return result
	}

	func visit(_ expr: ParamsExpr, _ context: Context) throws -> [RawSemanticToken] {
		return expr.params.map {
			make(.parameter, from: $0.location.start)
		}
	}

	func visit(_ expr: ReturnExpr, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.returnToken)]

		if let value = expr.value {
			try result.append(contentsOf: value.accept(self, context))
		}

		return result
	}

	func visit(_ expr: IdentifierExpr, _ context: Context) throws -> [RawSemanticToken] {
		[]
	}

	func visit(_ expr: MemberExpr, _ context: Context) throws -> [RawSemanticToken] {
		[]
	}

	func visit(_ expr: DeclBlockExpr, _ context: Context) throws -> [RawSemanticToken] {
		var result: [RawSemanticToken] = []

		for expr in expr.decls {
			try result.append(contentsOf: expr.accept(self, context))
		}

		return result
	}

	func visit(_ expr: StructExpr, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.structToken)]
		try result.append(contentsOf: expr.body.accept(self, .struct))
		return result
	}

	func visit(_ expr: any InitDecl, _ context: Context) throws -> [RawSemanticToken] {
		var result = [make(.keyword, from: expr.initToken)]
		try result.append(contentsOf: visit(expr.parameters, .initializer))
		try result.append(contentsOf: expr.body.accept(self, .initializer))
		return result
	}

	func visit(_ expr: VarDecl, _ context: Context) throws -> [RawSemanticToken] {
		return [
			make(.keyword, from: expr.token),
			make(.type, from: expr.typeDeclToken)
		]
	}

	func visit(_ expr: LetDecl, _ context: Context) throws -> [RawSemanticToken] {
		return [
			make(.keyword, from: expr.token),
			make(.type, from: expr.typeDeclToken)
		]
	}
}
