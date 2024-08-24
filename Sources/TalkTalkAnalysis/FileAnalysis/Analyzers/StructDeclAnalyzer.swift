//
//  StructDeclAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkSyntax

struct StructDeclAnalyzer: Analyzer {
	let decl: any StructDecl
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		var structType = StructType(
			name: decl.name,
			properties: [:],
			methods: [:],
			typeParameters: decl.genericParams?.params.map({
				TypeParameter(name: $0.type.identifier.lexeme, type: $0.type)
			}) ?? []
		)

		let bodyContext = context.addLexicalScope(
			scope: structType,
			type: .struct(decl.name),
			expr: decl
		)

		if let genericParams = decl.genericParams {
			for (i, param) in genericParams.params.enumerated() {
				// Go through and actually analyze the type params
				structType.typeParameters[i].type = try param.type.accept(visitor, bodyContext) as! AnalyzedTypeExpr
			}
		}

		let symbol = context.symbolGenerator.struct(decl.name, source: .internal)

		bodyContext.define(
			local: "self",
			as: AnalyzedVarExpr(
				typeID: TypeID(.instance(.struct(structType.name!))),
				expr: VarExprSyntax(
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

		context.define(struct: decl.name, as: structType)
		bodyContext.define(struct: decl.name, as: structType)

		// Do a first pass over the body decls so we have a basic idea of what's available in
		// this struct.
		for decl in decl.body.decls {
			switch decl {
			case let decl as VarDecl:
				var type = bodyContext.type(named: decl.typeExpr?.identifier.lexeme)

				if case .struct = type {
					type = .instance(
						InstanceValueType(
							ofType: type,
							boundGenericTypes: [:]
						)
					)
				}

				if case .generic = type {
					type = .instance(
						InstanceValueType(
							ofType: type,
							boundGenericTypes: [:]
						)
					)
				}

				let property = Property(
					slot: structType.properties.count,
					name: decl.name,
					typeID: TypeID(type),
					expr: decl,
					isMutable: true
				)
				structType.add(property: property)
			case let decl as LetDecl:
				var type = bodyContext.type(named: decl.typeExpr?.identifier.lexeme)

				if case .struct = type {
					type = .instance(
						InstanceValueType(
							ofType: type,
							boundGenericTypes: [:]
						)
					)
				}

				if case .generic = type {
					type = .instance(
						InstanceValueType(
							ofType: type,
							boundGenericTypes: [:]
						)
					)
				}

				structType.add(
					property: Property(
						slot: structType.properties.count,
						name: decl.name,
						typeID: TypeID(type),
						expr: decl,
						isMutable: false
					))
			case let decl as FuncExpr:
				if let name = decl.name {
					try structType.add(
						method: Method(
							symbol: .method(context.moduleName, structType.name!, name.lexeme, decl.params.params.map(\.name)),
							name: name.lexeme,
							slot: structType.methods.count,
							params: decl.params.params.map { try $0.accept(visitor, context) as! AnalyzedParam },
							typeID: TypeID(
								.function(
									name.lexeme,
									TypeID(.placeholder),
									decl
										.params
										.params
										.map { ValueType.Param(name: $0.name, typeID: TypeID(.placeholder)) },
									[]
								)
							),
							returnTypeID: TypeID(.placeholder),
							expr: decl,
							isMutable: false
						))
				} else {
					()
				}
			case let decl as InitDecl:
				try structType.add(
					initializer: .init(
						symbol: .method(context.moduleName, structType.name!, "init", decl.parameters.params.map(\.name)),
						name: "init",
						slot: structType.methods.count,
						params: decl.parameters.params.map { try $0.accept(visitor, context) as! AnalyzedParam },
						typeID: TypeID(
							.function(
								"init",
								TypeID(.placeholder),
								decl
									.parameters
									.params
									.map { ValueType.Param(name: $0.name, typeID: TypeID(.placeholder)) },
								[]
							)
						),
						returnTypeID: TypeID(.placeholder),
						expr: decl,
						isMutable: false
					))
			case is ParseError:
				()
			default:
				()
			}
		}

		// Do a second pass to try to fill in method returns
		let bodyAnalyzed = try visitor.visit(decl.body, bodyContext)

		let type: ValueType = .struct(
			structType.name ?? decl.description
		)

		// See if there's an initializer defined. If not, generate one.
		if structType.methods["init"] == nil {
			structType.add(
				initializer: .init(
					symbol: context.symbolGenerator.method(structType.name!, "init", parameters: structType.properties.reduce(into: []) { $0.append($1.key) }, source: .internal),
					name: "init",
					slot: structType.methods.count,
					params: structType.properties.reduce(into: []) { res, prop in
						res.append(
							AnalyzedParam(type: prop.value.typeID, expr: .synthetic(name: prop.key), environment: context)
						)
					},
					typeID: TypeID(
						.function(
							"init",
							TypeID(.placeholder),
							[],
							[]
						)
					),
					returnTypeID: TypeID(.placeholder),
					expr: decl,
					isMutable: false,
					isSynthetic: true
				))
		}

		let lexicalScope = bodyContext.getLexicalScope()!

		let analyzed = AnalyzedStructDecl(
			symbol: symbol,
			wrapped: decl,
			bodyAnalyzed: bodyAnalyzed as! AnalyzedDeclBlock,
			structType: structType,
			lexicalScope: lexicalScope,
			typeID: TypeID(type),
			environment: context
		)

		context.define(local: decl.name, as: analyzed, isMutable: false)

		bodyContext.lexicalScope = lexicalScope

		return analyzed
	}
}
