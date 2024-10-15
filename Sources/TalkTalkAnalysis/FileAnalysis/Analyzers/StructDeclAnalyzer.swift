//
//  StructDeclAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkBytecode
import TalkTalkCore
import TypeChecker

struct StructDeclAnalyzer: Analyzer {
	let decl: any StructDecl
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let inferenceType = context.type(for: decl)
		guard let type = StructType.extract(from: inferenceType)
		else {
			return error(at: decl, "did not find struct type from \(decl.name), got \(inferenceType)", environment: context, expectation: .none)
		}

		let structType = AnalysisStructType(
			id: decl.id,
			name: decl.name,
			properties: [:],
			methods: [:],
			typeParameters: decl.typeParameters.map {
				TypeParameter(name: $0.identifier.lexeme, type: $0)
			}
		)

		for decl in decl.body.decls {
			switch decl {
			case let decl as PropertyDecl:
				structType.add(
					property: Property(
						symbol: .property(context.moduleName, structType.name, decl.name.lexeme),
						name: decl.name.lexeme,
						inferenceType: context.type(for: decl),
						location: decl.semanticLocation ?? decl.location,
						isMutable: false,
						isStatic: decl.isStatic
					)
				)
			case let decl as MethodDecl:
				let method = context.type(for: decl)
				guard case let .function(params, returns) = method else {
					let name = decl.nameToken.lexeme
					return error(at: decl, "invalid method", environment: context, expectation: .none)
				}

				let symbol = context.symbolGenerator.method(
					structType.name,
					decl.nameToken.lexeme,
					parameters: params.map(\.mangled),
					source: .internal
				)

				structType.add(
					method: Method(
						name: decl.nameToken.lexeme,
						symbol: symbol,
						params: params.map { context.inferenceContext.apply($0) },
						inferenceType: method,
						location: decl.semanticLocation ?? decl.location,
						returnTypeID: context.inferenceContext.apply(returns),
						isStatic: decl.isStatic
					)
				)
			case let decl as InitDecl:
				let initializer = context.type(for: decl)
				guard case let .function(params, returns) = initializer else {
					return error(at: decl, "invalid method", environment: context, expectation: .none)
				}

				let symbol = context.symbolGenerator.method(
					structType.name,
					"init",
					parameters: params.map { context.inferenceContext.apply($0).mangled },
					source: .internal
				)

				structType.add(
					initializer: Method(
						name: "init",
						symbol: symbol,
						params: params.map { context.inferenceContext.apply($0) },
						inferenceType: initializer,
						location: decl.semanticLocation ?? decl.location,
						returnTypeID: context.inferenceContext.apply(returns)
					)
				)
			default:
				continue
			}
		}

		//		// If there's no init, synthesize one
		if structType.methods["init"] == nil {
			structType.add(
				initializer: Method(
					name: "init",
					symbol: context.symbolGenerator.method(
						context.moduleName,
						structType.name,
						parameters: structType.properties.values.map(\.inferenceType.mangled),
						source: .internal
					),
					params: structType.properties.values.map(\.inferenceType),
					inferenceType: .function(structType.properties.values.map { .resolved($0.inferenceType) }, .resolved(.type(.struct(type)))),
					location: decl.location,
					returnTypeID: .instance(.struct(Instance(type: type))),
					isSynthetic: true
				)
			)
		}

		let bodyContext = context.addLexicalScope(for: structType)

		bodyContext.define(
			local: "self",
			as: AnalyzedVarExpr(
				inferenceType: .instance(.struct(Instance(type: type))),
				wrapped: VarExprSyntax(
					id: -8,
					token: .synthetic(.self),
					location: [.synthetic(.self)]
				),
				symbol: bodyContext.symbolGenerator.value("self", source: .internal),
				environment: bodyContext,
				analysisErrors: [],
				isMutable: false
			),
			type: .instance(.struct(Instance(type: type))),
			isMutable: false
		)

		for (i, param) in structType.typeParameters.enumerated() {
			// Go through and actually analyze the type params
			let environment = bodyContext.add(namespace: nil)
			environment.isInTypeParameters = true

			guard let expr = try param.type.accept(visitor, environment) as? AnalyzedTypeExpr else {
				return error(at: param.type, "Could not cast \(param.type) to AnalyzedTypeExpr", environment: context)
			}

			structType.typeParameters[i].type = expr
		}

		context.define(type: decl.name, as: structType)

		let symbol = context.symbolGenerator.struct(decl.name, source: .internal)
		let bodyAnalyzed = try visitor.visit(decl.body, bodyContext)

		var errors: [AnalysisError] = []
		for error in context.inferenceContext.diagnostics {
			errors.append(
				.init(
					kind: .unknownError(error.message),
					location: error.location
				)
			)
		}

		guard let decl = decl as? StructDeclSyntax else {
			return error(at: decl, "Could not cast \(decl) to StructDeclSyntax", environment: context)
		}

		guard let bodyAnalyzed = bodyAnalyzed as? AnalyzedDeclBlock else {
			return error(at: decl, "Could not cast \(bodyAnalyzed) to AnalyzedDeclBlock", environment: context)
		}

		let analyzed = AnalyzedStructDecl(
			symbol: symbol,
			wrapped: decl,
			bodyAnalyzed: bodyAnalyzed,
			structType: structType,
			inferenceType: inferenceType,
			analysisErrors: errors,
			environment: context
		)

		bodyContext.define(type: decl.name, as: structType)

		context.define(local: decl.name, as: analyzed, isMutable: false)

		return analyzed
	}
}
