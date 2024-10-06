//
//  FuncExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkBytecode
import TalkTalkCore

struct FuncExprAnalyzer: Analyzer {
	var expr: FuncExprSyntax
	var visitor: SourceFileAnalyzer
	var context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let type = context.type(for: expr)
		let symbol: Symbol = if let lexicalScope = context.lexicalScope {
			context.symbolGenerator.method(
				lexicalScope.type.name,
				expr.autoname,
				parameters: expr.params.params.map { context.type(for: $0).mangled },
				source: .internal
			)
		} else {
			context.symbolGenerator.function(
				expr.autoname,
				parameters: expr.params.params.map { context.type(for: $0).mangled },
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
		let syntax = try expr.params.accept(visitor, context)
		guard let params = syntax as? AnalyzedParamsExpr else {
			return castError(at: expr.params, type: AnalyzedParamsExpr.self, in: context)
		}

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

		guard let body = try expr.body.accept(visitor, environment) as? AnalyzedBlockStmt else {
			return castError(at: expr.body, type: AnalyzedBlockStmt.self, in: context)
		}

		return AnalyzedFuncExpr(
			symbol: symbol,
			type: type,
			wrapped: expr,
			analyzedParams: params,
			bodyAnalyzed: body,
			analysisErrors: visitor.errors(for: expr, in: context.inferenceContext),
			returnType: returns,
			environment: environment
		)
	}
}
