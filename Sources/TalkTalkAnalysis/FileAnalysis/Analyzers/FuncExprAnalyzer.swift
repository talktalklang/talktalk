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
		let symbol: Symbol
		if let scope = context.lexicalScope {
			symbol = context.symbolGenerator.method(scope.scope.name!, expr.autoname, parameters: [], source: .internal)
		} else {
			symbol = context.symbolGenerator.function(expr.autoname, parameters: [], source: .internal)
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

		// Find the actual type of the fn
		let type = context.inferenceContext.lookup(syntax: expr)

		let returns = if case let .function(_, fnReturns) = type {
			fnReturns
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

		return AnalyzedFuncExpr(
			symbol: symbol,
			type: type ?? .any,
			wrapped: try cast(expr, to: FuncExprSyntax.self),
			analyzedParams: params,
			bodyAnalyzed: try cast(params, to: AnalyzedBlockStmt.self),
			analysisErrors: visitor.errors(for: expr, in: context.inferenceContext),
			returnType: returns,
			environment: environment
		)
	}
}
