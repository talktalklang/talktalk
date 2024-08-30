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
		let structType = StructType(
			name: decl.name,
			properties: [:],
			methods: [:],
			typeParameters: decl.typeParameters.map({
				TypeParameter(name: $0.identifier.lexeme, type: $0)
			})
		)

		let lexicalScope = LexicalScope(scope: structType, expr: decl)
		let bodyContext = context.addLexicalScope(lexicalScope)

		for (i, param) in structType.typeParameters.enumerated() {
			// Go through and actually analyze the type params
			let environment = bodyContext.add(namespace: nil)
			environment.isInTypeParameters = true
			structType.typeParameters[i].type = try param.type.accept(visitor, environment) as! AnalyzedTypeExpr
		}

		let symbol = context.symbolGenerator.struct(decl.name, source: .internal)

		// Do a second pass to try to fill in method returns
		let bodyAnalyzed = try visitor.visit(decl.body.cast(DeclBlockSyntax.self), bodyContext)

		let analyzed = AnalyzedStructDecl(
			symbol: symbol,
			wrapped: decl.cast(StructDeclSyntax.self),
			bodyAnalyzed: bodyAnalyzed as! AnalyzedDeclBlock,
			structType: structType,
			lexicalScope: lexicalScope,
			inferenceType: context.inferenceContext.lookup(syntax: decl)!,
			environment: context
		)

		bodyContext.lexicalScope = lexicalScope

		return analyzed
	}
}
