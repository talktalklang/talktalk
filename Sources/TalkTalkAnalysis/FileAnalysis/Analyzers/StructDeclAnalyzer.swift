//
//  StructDeclAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkBytecode
import TalkTalkSyntax
import TypeChecker

struct ConformanceRequirement: Hashable {
	let name: String
	let type: InferenceResult
}

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

		var conformanceRequirements: [ConformanceRequirement: [ProtocolType]] = [:]
		for conformance in decl.conformances {
			guard case let .protocol(conformanceType) = context.inferenceContext.lookup(syntax: conformance) else {
				return error(at: conformance, "Could not determine conformance requirements for \(conformance.identifier.lexeme)", environment: context)
			}

			for (name, method) in conformanceType.properties {
				let req = ConformanceRequirement(name: name, type: method)
				conformanceRequirements[req, default: []].append(conformanceType)
			}

			for (name, method) in conformanceType.methods {
				let req = ConformanceRequirement(name: name, type: method)
				conformanceRequirements[req, default: []].append(conformanceType)
			}
		}

		for (name, type) in type.properties {
			let location = decl.body.decls.first(where: { ($0 as? VarLetDecl)?.name == name })?.semanticLocation

			// Make this requirement as satisfied
			conformanceRequirements.removeValue(forKey: .init(name: name, type: type))

			structType.add(
				property: Property(
					symbol: .property(context.moduleName, structType.name ?? "", name),
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

			// Make this requirement as satisfied
			conformanceRequirements.removeValue(forKey: .init(name: name, type: type))

			let location = decl.body.decls.first(where: { ($0 as? FuncExpr)?.name?.lexeme == name })?.semanticLocation

			let symbol = context.symbolGenerator.method(
				structType.name ?? "",
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
				structType.name ?? "",
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
						structType.name ?? "",
						parameters: structType.properties.keys.map(\.description),
						source: .internal
					),
					params: structType.properties.values.map(\.inferenceType),
					inferenceType: .function(structType.properties.values.map(\.inferenceType), .structType(type)),
					location: decl.location,
					returnTypeID: .structInstance(.synthesized(type)),
					isSynthetic: true
				)
			)
		}

		let bodyContext = context.addLexicalScope(for: type)

		bodyContext.define(
			local: "self",
			as: AnalyzedVarExpr(
				inferenceType: .structInstance(.synthesized(type)),
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
		for (type, conformances) in conformanceRequirements {
			errors.append(
				.init(
					kind: .conformanceError(
						name: type.name,
						type: type.type.asType(in: context.inferenceContext),
						conformances: conformances
					),
					location: decl.location
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

		context.define(struct: decl.name, as: structType)
		bodyContext.define(struct: decl.name, as: structType)

		context.define(local: decl.name, as: analyzed, isMutable: false)

		return analyzed
	}
}
