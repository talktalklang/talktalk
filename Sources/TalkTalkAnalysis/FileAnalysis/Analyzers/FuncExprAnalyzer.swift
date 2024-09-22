//
//  FuncExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

struct FuncExprAnalyzer: Analyzer {
	var expr: any FuncExpr
	var visitor: SourceFileAnalyzer
	var context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		guard let type = context.inferenceContext.lookup(syntax: expr) else {
			return error(at: expr, "Could not determine type of \(expr)", environment: context)
		}

		let symbol: Symbol = if let lexicalScope = context.lexicalScope {
			context.symbolGenerator.method(
				lexicalScope.type.name,
				expr.autoname,
				parameters: expr.params.params.map { context.inferenceContext.lookup(syntax: $0)?.description ?? "_" },
				source: .internal
			)
		} else {
			context.symbolGenerator.function(
				expr.autoname,
				parameters: expr.params.params.map { context.inferenceContext.lookup(syntax: $0)?.description ?? "_" },
				source: .internal
			)
		}

		// If a block has one statement, we can treat it as a return value
		let environment = if expr.body.stmts.count == 1 {
			context.withExitBehavior(.return)
		} else {
			context.withExitBehavior(.pop)
		}

		// Define parameters
		let syntax = try visitor.visit(expr.params.cast(ParamsExprSyntax.self), context)
		let params = try cast(syntax, to: AnalyzedParamsExpr.self)
		for param in params.paramsAnalyzed {
			environment.define(parameter: param.name, as: param)
		}

		let returns = if case let .function(_, fnReturns) = type {
			context.inferenceContext.apply(fnReturns)
		} else {
			InferenceType.void
		}

		// Define the function by name if it has one
		if let name = expr.name {
			context.define(
				local: name.lexeme,
				as: expr,
				isMutable: false,
				isGlobal: environment.isModuleScope
			)
		}

		let body = try expr.body.accept(visitor, environment)

		return try AnalyzedFuncExpr(
			symbol: symbol,
			type: type,
			wrapped: cast(expr, to: FuncExprSyntax.self),
			analyzedParams: params,
			bodyAnalyzed: cast(body, to: AnalyzedBlockStmt.self),
			analysisErrors: visitor.errors(for: expr, in: context.inferenceContext),
			returnType: returns,
			environment: environment
		)
	}
}
