//
//  FuncExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkSyntax
import TalkTalkBytecode

struct FuncExprAnalyzer {
	var expr: any FuncExpr
	var visitor: SourceFileAnalyzer
	var context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let symbol: Symbol
		if let scope = context.lexicalScope {
			symbol = context.symbolGenerator.method(scope.scope.name!, expr.autoname, parameters: [], source: .internal, id: expr.id)
		} else {
			symbol = context.symbolGenerator.function(expr.autoname, parameters: [], source: .internal, id: expr.id)
		}

		let type = context.inferenceContext.lookup(syntax: expr)!

		let returns = if case let .function(_, fnReturns) = type {
			fnReturns
		} else {
			InferenceType.void
		}

		let environment = if expr.body.stmts.count == 1 {
			context.withExitBehavior(.return)
		} else {
			context.withExitBehavior(.pop)
		}

		return try AnalyzedFuncExpr(
			symbol: symbol,
			type: type,
			wrapped: expr as! FuncExprSyntax,
			analyzedParams: expr.params.accept(visitor, environment) as! AnalyzedParamsExpr,
			bodyAnalyzed: expr.body.accept(visitor, environment) as! AnalyzedBlockStmt,
			analysisErrors: [],
			returnType: returns,
			environment: environment
		)
	}
}
