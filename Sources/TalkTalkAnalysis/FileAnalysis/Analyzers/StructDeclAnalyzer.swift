//
//  StructDeclAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkSyntax
import TypeChecker

struct StructDeclAnalyzer: Analyzer {
	let decl: any StructDecl
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		guard let inferenceType = context.inferenceContext.lookup(syntax: decl),
					let type = TypeChecker.StructType.extractType(from: .type(inferenceType)) else {
			return error(at: decl, "did not find struct type", environment: context, expectation: .none)
		}

		let structType = StructType(
			name: decl.name,
			properties: [:],
			methods: [:],
			typeParameters: decl.typeParameters.map({
				TypeParameter(name: $0.identifier.lexeme, type: $0)
			})
		)

		for (name, type) in type.properties {
			structType.add(
				property: Property(
					slot: structType.properties.count,
					name: name,
					inferenceType: type.asType(in: context.inferenceContext),
					isMutable: false
				)
			)
		}

		for (name, type) in type.methods {
			guard case let .function(params, returns) = type.asType(in: context.inferenceContext) else {
				return error(at: decl, "invalid method", environment: context, expectation: .none)
			}

			structType.add(
				method: Method(
					name: name,
					slot: structType.methods.count,
					params: params,
					inferenceType: type.asType(in: context.inferenceContext),
					returnTypeID: returns
				)
			)
		}

		for (name, type) in type.initializers {
			guard case let .function(params, returns) = type.asType(in: context.inferenceContext) else {
				return error(at: decl, "invalid method", environment: context, expectation: .none)
			}

			structType.add(
				initializer: Method(
					name: name,
					slot: structType.methods.count,
					params: params,
					inferenceType: type.asType(in: context.inferenceContext),
					returnTypeID: returns
				)
			)
		}

		// If there's no init, synthesize one
		if structType.methods["init"] == nil {
			structType.add(initializer: Method(
				name: "init",
				slot: structType.methods.count,
				params: structType.properties.values.map(\.inferenceType),
				inferenceType: .function(structType.properties.values.map(\.inferenceType), .structType(type)),
				returnTypeID: .structInstance(.synthesized(type))
			))
		}

		let lexicalScope = LexicalScope(scope: structType, expr: decl)
		let bodyContext = context.addLexicalScope(lexicalScope)

		for (i, param) in structType.typeParameters.enumerated() {
			// Go through and actually analyze the type params
			let environment = bodyContext.add(namespace: nil)
			environment.isInTypeParameters = true
			structType.typeParameters[i].type = try param.type.accept(visitor, environment) as! AnalyzedTypeExpr
		}

		let symbol = context.symbolGenerator.struct(decl.name, source: .internal, id: decl.id)

		// Do a second pass to try to fill in method returns
		let bodyAnalyzed = try visitor.visit(decl.body.cast(DeclBlockSyntax.self), bodyContext)

		let analyzed = AnalyzedStructDecl(
			symbol: symbol,
			wrapped: decl.cast(StructDeclSyntax.self),
			bodyAnalyzed: bodyAnalyzed as! AnalyzedDeclBlock,
			structType: structType,
			lexicalScope: lexicalScope,
			inferenceType: inferenceType,
			environment: context
		)

		context.define(struct: structType.name!, as: structType)

		bodyContext.lexicalScope = lexicalScope

		return analyzed
	}
}
