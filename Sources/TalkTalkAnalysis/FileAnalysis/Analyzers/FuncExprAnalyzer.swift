//
//  FuncExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkSyntax

struct FuncExprAnalyzer {
	var expr: any FuncExpr
	var visitor: SourceFileAnalyzer
	var context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		var errors: [AnalysisError] = []
		let innerEnvironment = context.add(namespace: expr.autoname)

		// Define our parameters in the environment so they're declared in the body. They're
		// just placeholders for now.
		var params = try visitor.visit(expr.params, context) as! AnalyzedParamsExpr
		for param in params.paramsAnalyzed {
			innerEnvironment.define(parameter: param.name, as: param)
		}

		let symbol = if let scope = context.getLexicalScope() {
			context.symbolGenerator.method(scope.scope.name ?? scope.expr.description, expr.autoname, parameters: params.paramsAnalyzed.map(\.name), source: .internal)
		} else {
			context.symbolGenerator.function(expr.autoname, parameters: params.paramsAnalyzed.map(\.name), source: .internal)
		}

		if let name = expr.name {
			// If it's a named function, define a stub inside the function to allow for recursion
			let stubType = ValueType.function(
				name.lexeme,
				TypeID(.placeholder),
				params.paramsAnalyzed.map {
					.init(name: $0.name, typeID: $0.typeID)
				},
				[]
			)
			let stub = AnalyzedFuncExpr(
				symbol: symbol,
				type: TypeID(stubType),
				expr: expr,
				analyzedParams: params,
				bodyAnalyzed: .init(
					stmt: expr.body,
					typeID: TypeID(),
					stmtsAnalyzed: [],
					environment: context
				),
				analysisErrors: [],
				returnType: TypeID(.placeholder),
				environment: innerEnvironment
			)
			innerEnvironment.define(local: name.lexeme, as: stub, isMutable: false)
		}

		// Visit the body with the innerEnvironment, finding captures as we go.
		let exitBehavior: AnalyzedExprStmt.ExitBehavior = expr.body.stmts.count == 1 ? .return : .pop
		innerEnvironment.exprStmtExitBehavior = exitBehavior

		let bodyAnalyzed = try visitor.visit(expr.body, innerEnvironment) as! AnalyzedBlockStmt

		var declaredType: TypeID?
		if let typeDecl = expr.typeDecl {
			if let type = context.type(named: typeDecl.identifier.lexeme) {
				declaredType = TypeID(type)
				if !type.isAssignable(from: bodyAnalyzed.typeID.current) {
					errors.append(
						.init(
							kind: .unexpectedType(
								expected: type,
								received: bodyAnalyzed.typeAnalyzed,
								message: "Cannot return \(bodyAnalyzed.typeAnalyzed.description), expected \(type.description)."
							),
							location: bodyAnalyzed.stmtsAnalyzed.last?.location ?? expr.location
						)
					)
				}
			}
		}

		// See if we can infer any types for our params from the environment after the body
		// has been visited.
		params.infer(from: innerEnvironment)

		let analyzed = ValueType.function(
			expr.name?.lexeme ?? expr.autoname,
			declaredType ?? bodyAnalyzed.typeID,
			params.paramsAnalyzed.map { .init(name: $0.name, typeID: $0.typeID) },
			innerEnvironment.captures.map(\.name)
		)

		let funcExpr = AnalyzedFuncExpr(
			symbol: symbol,
			type: TypeID(analyzed),
			expr: expr,
			analyzedParams: params,
			bodyAnalyzed: bodyAnalyzed,
			analysisErrors: errors,
			returnType: declaredType ?? bodyAnalyzed.typeID,
			environment: innerEnvironment
		)

		if let name = expr.name {
			innerEnvironment.define(local: name.lexeme, as: funcExpr, isMutable: false)
			context.define(local: name.lexeme, as: funcExpr, isMutable: false)
		}

		return funcExpr
	}
}
