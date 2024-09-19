//
//  StructDeclAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkBytecode
import TalkTalkSyntax
import TypeChecker

struct StructDeclAnalyzer: Analyzer {
	let decl: any StructDecl
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		guard let inferenceType = context.inferenceContext.lookup(syntax: decl),
		      let type = TypeChecker.StructType.extractType(from: .type(inferenceType))
		else {
			return error(at: decl, "did not find struct type from \(decl.name)", environment: context, expectation: .none)
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

		for (name, type) in type.properties {
			let location = decl.body.decls.first(where: { ($0 as? VarLetDecl)?.name == name })?.semanticLocation

			structType.add(
				property: Property(
					symbol: .property(context.moduleName, structType.name, name),
					name: name,
					inferenceType: type.asType(in: context.inferenceContext),
					location: location ?? decl.location,
					isMutable: false
				)
			)
		}

		for (name, type) in type.methods {
			guard case let .function(params, returns) = type.asType(in: context.inferenceContext) else {
				return error(at: decl, "invalid method", environment: context, expectation: .none)
			}

			let location = decl.body.decls.first(where: { ($0 as? FuncExpr)?.name?.lexeme == name })?.semanticLocation

			let symbol = context.symbolGenerator.method(
				structType.name,
				name,
				parameters: params.map(\.description),
				source: .internal
			)

			structType.add(
				method: Method(
					name: name,
					symbol: symbol,
					params: params,
					inferenceType: type.asType(in: context.inferenceContext),
					location: location ?? decl.location,
					returnTypeID: returns
				)
			)
		}

		for (name, type) in type.initializers {
			guard case let .function(params, returns) = type.asType(in: context.inferenceContext) else {
				return error(at: decl, "invalid method", environment: context, expectation: .none)
			}

			let location = decl.body.decls.first(where: { $0 is InitDecl })?.semanticLocation
			let symbol = context.symbolGenerator.method(
				structType.name,
				name,
				parameters: params.map(\.description),
				source: .internal
			)

			structType.add(
				initializer: Method(
					name: name,
					symbol: symbol,
					params: params,
					inferenceType: type.asType(in: context.inferenceContext),
					location: location ?? decl.location,
					returnTypeID: returns
				)
			)
		}

		// If there's no init, synthesize one
		if structType.methods["init"] == nil {
			structType.add(
				initializer: Method(
					name: "init",
					symbol: context.symbolGenerator.method(
						context.moduleName,
						structType.name,
						parameters: structType.properties.keys.map(\.description),
						source: .internal
					),
					params: structType.properties.values.map(\.inferenceType),
					inferenceType: .function(structType.properties.values.map(\.inferenceType), .instantiatable(.struct(type))),
					location: decl.location,
					returnTypeID: .instance(.synthesized(type)),
					isSynthetic: true
				)
			)
		}

		let bodyContext = context.addLexicalScope(for: structType)

		bodyContext.define(
			local: "self",
			as: AnalyzedVarExpr(
				inferenceType: .instance(.synthesized(type)),
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
			type: .instance(.synthesized(type)),
			isMutable: false
		)

		for (i, param) in structType.typeParameters.enumerated() {
			// Go through and actually analyze the type params
			let environment = bodyContext.add(namespace: nil)
			environment.isInTypeParameters = true
			structType.typeParameters[i].type = try cast(param.type.accept(visitor, environment), to: AnalyzedTypeExpr.self)
		}

		let symbol = context.symbolGenerator.struct(decl.name, source: .internal)
		let bodyAnalyzed = try visitor.visit(decl.body, bodyContext)

		var errors: [AnalysisError] = []
		for error in context.inferenceContext.errors {
			errors.append(
				.init(
					kind: .inferenceError(error.kind),
					location: error.location
				)
			)
		}

		let analyzed = try AnalyzedStructDecl(
			symbol: symbol,
			wrapped: cast(decl, to: StructDeclSyntax.self),
			bodyAnalyzed: cast(bodyAnalyzed, to: AnalyzedDeclBlock.self),
			structType: structType,
			inferenceType: inferenceType,
			analysisErrors: errors,
			environment: context
		)

		context.define(type: decl.name, as: structType)
		bodyContext.define(type: decl.name, as: structType)

		context.define(local: decl.name, as: analyzed, isMutable: false)

		return analyzed
	}
}
