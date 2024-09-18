//
//  Analyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//
import Foundation
import TalkTalkBytecode
import TalkTalkSyntax
import TypeChecker

// Analyze the AST, trying to figure out types and also checking for errors
public struct SourceFileAnalyzer: Visitor, Analyzer {
	public typealias Context = Environment
	public typealias Value = any AnalyzedSyntax

	var errors: [String] = []

	public init() {}

	public static func analyze(_ exprs: [any Syntax], in environment: Environment) throws
		-> [Value]
	{
		let analyzer = SourceFileAnalyzer()
		let analyzed = try exprs.map {
			try $0.accept(analyzer, environment)
		}

		return analyzed
	}

	public func visit(_ expr: ExprStmtSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		let exprAnalyzed = try expr.expr.accept(self, context)

		return try AnalyzedExprStmt(
			wrapped: cast(expr, to: ExprStmtSyntax.self),
			exprAnalyzed: castToAnyAnalyzedExpr(exprAnalyzed),
			exitBehavior: context.exprStmtExitBehavior,
			environment: context
		)
	}

	public func visit(_ expr: ImportStmtSyntax, _ context: Environment) -> SourceFileAnalyzer.Value {
		AnalyzedImportStmt(
			environment: context,
			inferenceType: .void,
			wrapped: expr.cast(ImportStmtSyntax.self)
		)
	}

	public func visit(_ expr: IdentifierExprSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		AnalyzedIdentifierExpr(
			inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
			wrapped: expr.cast(IdentifierExprSyntax.self),
			environment: context
		)
	}

	public func visit(_ expr: UnaryExprSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		let exprAnalyzed = try expr.expr.accept(self, context)

		switch expr.op {
		case .bang:

			return try AnalyzedUnaryExpr(
				inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
				exprAnalyzed: castToAnyAnalyzedExpr(exprAnalyzed),
				environment: context,
				wrapped: expr.cast(UnaryExprSyntax.self)
			)
		case .minus:
			return try AnalyzedUnaryExpr(
				inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
				exprAnalyzed: castToAnyAnalyzedExpr(exprAnalyzed),
				environment: context,
				wrapped: expr.cast(UnaryExprSyntax.self)
			)
		default:
			throw AnalyzerError.typeNotInferred("")
		}
	}

	public func visit(_ expr: Argument, _ context: Environment) throws -> any AnalyzedSyntax {
		try AnalyzedArgument(
			environment: context,
			label: expr.label,
			wrapped: expr.cast(Argument.self),
			expr: castToAnyAnalyzedExpr(expr.value.accept(self, context))
		)
	}

	public func visit(_ expr: CallExprSyntax, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		try CallExprAnalyzer(expr: expr, visitor: self, context: context).analyze()
	}

	public func visit(_ expr: MemberExprSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		try MemberExprAnalyzer(expr: expr, visitor: self, context: context).analyze()
	}

	public func visit(_ expr: DefExprSyntax, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		let value = try castToAnyAnalyzedExpr(expr.value.accept(self, context))
		let receiver = try castToAnyAnalyzedExpr(expr.receiver.accept(self, context))

		var errors = errors(for: expr, in: context.inferenceContext)

		errors.append(contentsOf: checkMutability(of: expr.receiver, in: context))

		return try AnalyzedDefExpr(
			inferenceType: .void,
			wrapped: cast(expr, to: DefExprSyntax.self),
			receiverAnalyzed: receiver,
			analysisErrors: errors,
			valueAnalyzed: value,
			environment: context
		)
	}

	public func visit(_ expr: ParseErrorSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		AnalyzedErrorSyntax(
			typeID: .error(.init(kind: .unknownError(expr.message), location: expr.location)),
			wrapped: expr.cast(ParseErrorSyntax.self),
			environment: context
		)
	}

	public func visit(_ expr: LiteralExprSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		guard let type = context.inferenceContext.lookup(syntax: expr) else {
			print("Did not get type for \(expr.description)")
			return AnalyzedLiteralExpr(
				inferenceType: .any,
				wrapped: expr.cast(LiteralExprSyntax.self),
				environment: context
			)
		}

		return AnalyzedLiteralExpr(
			inferenceType: type,
			wrapped: expr.cast(LiteralExprSyntax.self),
			environment: context
		)
	}

	public func visit(_ expr: VarExprSyntax, _ context: Environment) throws -> Value {
		if let binding = context.lookup(expr.name) {
			var symbol: Symbol? = nil

			if case let .instantiatable(type as StructType) = binding.type {
				if let module = binding.externalModule {
					symbol = module.structs[type.name]?.symbol
					guard symbol != nil else {
						throw AnalyzerError.symbolNotFound("expected symbol for struct: \(type.name)")
					}
				} else {
					symbol = context.symbolGenerator.struct(expr.name, source: .internal)
				}
			} else if case .function = binding.type {
				if let module = binding.externalModule {
					symbol = module.moduleFunction(named: binding.name)?.symbol
					guard symbol != nil else {
						throw AnalyzerError.symbolNotFound("expected symbol for external function: \(binding.name)")
					}
				} else if binding.isGlobal {
					symbol = context.symbolGenerator.value(expr.name, source: .internal)
				}
			} else if case let .instantiatable(type as EnumType) = binding.type {
				if let module = binding.externalModule {
					symbol = module.enums[type.name]?.symbol
					guard symbol != nil else {
						throw AnalyzerError.symbolNotFound("expected symbol for struct: \(type.name)")
					}
				} else {
					symbol = context.symbolGenerator.enum(type.name, source: .internal)
				}
			} else {
				if let module = binding.externalModule {
					symbol = module.values[expr.name]?.symbol
					guard symbol != nil else {
						throw AnalyzerError.symbolNotFound("expected symbol for external value: \(binding)")
					}
				} else {
					if binding.isGlobal {
						symbol = context.symbolGenerator.value(expr.name, source: .internal)
					}
				}
			}

			return try AnalyzedVarExpr(
				inferenceType: binding.type,
				wrapped: cast(expr, to: VarExprSyntax.self),
				symbol: symbol,
				environment: context,
				analysisErrors: [],
				isMutable: binding.isMutable
			)
		}

		let errors: [AnalysisError] = context.shouldReportErrors ?
			[AnalysisError(kind: .undefinedVariable(expr.name), location: expr.location)] :
			[]

		return AnalyzedVarExpr(
			inferenceType: .any,
			wrapped: expr.cast(VarExprSyntax.self),
			symbol: context.symbolGenerator.value(expr.name, source: .internal),
			environment: context,
			analysisErrors: errors,
			isMutable: false
		)
	}

	public func visit(_ expr: BinaryExprSyntax, _ env: Environment) throws -> SourceFileAnalyzer.Value {
		let lhs = try castToAnyAnalyzedExpr(expr.lhs.accept(self, env))
		let rhs = try castToAnyAnalyzedExpr(expr.rhs.accept(self, env))

		return try AnalyzedBinaryExpr(
			inferenceType: env.inferenceContext.lookup(syntax: expr) ?? .any,
			wrapped: cast(expr, to: BinaryExprSyntax.self),
			lhsAnalyzed: lhs,
			rhsAnalyzed: rhs,
			environment: env
		)
	}

	public func visit(_ expr: IfExprSyntax, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		var errors: [AnalysisError] = []

		switch expr.consequence.stmts.count {
		case 0:
			errors.append(.init(kind: .expressionCount("Expected one expression inside then block"), location: expr.consequence.location))
		case 1:
			()
		default:
			errors.append(
				.init(
					kind: .expressionCount("Only 1 expression is allowed in an if expression block"),
					location: expr.consequence.stmts[expr.consequence.stmts.count - 1].location
				)
			)
		}

		switch expr.alternative.stmts.count {
		case 0:
			errors.append(.init(kind: .expressionCount("Expected one expression inside then block"), location: expr.alternative.location))
		case 1:
			()
		default:
			errors.append(
				.init(
					kind: .expressionCount("Only 1 expression is allowed in an if expression block"),
					location: expr.alternative.stmts[expr.alternative.stmts.count - 1].location
				)
			)
		}

		// We always want if exprs to be able to return their value
		let context = context.withExitBehavior(.none)

		// TODO: Error if the branches don't match or condition isn't a bool
		return try AnalyzedIfExpr(
			inferenceType: expr.consequence.accept(self, context).inferenceType,
			wrapped: expr.cast(IfExprSyntax.self),
			conditionAnalyzed: castToAnyAnalyzedExpr(expr.condition.accept(self, context)),
			consequenceAnalyzed: cast(visit(expr.consequence.cast(BlockStmtSyntax.self), context), to: AnalyzedBlockStmt.self),
			alternativeAnalyzed: cast(visit(expr.alternative.cast(BlockStmtSyntax.self), context), to: AnalyzedBlockStmt.self),
			environment: context,
			analysisErrors: errors
		)
	}

	public func visit(_ expr: TypeExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		let symbol: Symbol = switch context.inferenceContext.lookup(syntax: expr) {
		case .typeVar:
			context.symbolGenerator.generic(expr.identifier.lexeme, source: .internal)
		case let .base(type):
			.primitive("\(type)")
		case .instantiatable(_ as StructType):
			context.symbolGenerator.struct(expr.identifier.lexeme, source: .internal)
		case .instantiatable(_ as EnumType):
			context.symbolGenerator.enum(expr.identifier.lexeme, source: .internal)
		case .instantiatable(_ as ProtocolType):
			context.symbolGenerator.protocol(expr.identifier.lexeme, source: .internal)
		default:
			context.symbolGenerator.generic("error", source: .internal)
		}

		return AnalyzedTypeExpr(
			wrapped: expr.cast(TypeExprSyntax.self),
			symbol: symbol,
			inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
			environment: context
		)
	}

	public func visit(_ expr: FuncExprSyntax, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		try FuncExprAnalyzer(expr: expr, visitor: self, context: context).analyze()
	}

	public func visit(_ expr: InitDeclSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		guard let lexicalScope = context.getLexicalScope() else {
			return error(at: expr, "Could not determine lexical scope for init", environment: context, expectation: .none)
		}

		let paramsAnalyzed = try cast(expr.params.accept(self, context), to: AnalyzedParamsExpr.self)
		let bodyAnalyzed = try cast(expr.body.accept(self, context), to: AnalyzedBlockStmt.self)

		return AnalyzedInitDecl(
			wrapped: expr.cast(InitDeclSyntax.self),
			symbol: context.symbolGenerator.method(
				lexicalScope.type.name,
				"init",
				parameters: paramsAnalyzed.paramsAnalyzed.map(\.inferenceType.description),
				source: .internal
			),
			inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
			environment: context,
			parametersAnalyzed: paramsAnalyzed,
			bodyAnalyzed: bodyAnalyzed
		)
	}

	public func visit(_ expr: ReturnStmtSyntax, _ env: Environment) throws -> SourceFileAnalyzer.Value {
		let valueAnalyzed = try expr.value?.accept(self, env)
		return AnalyzedReturnStmt(
			inferenceType: env.inferenceContext.lookup(syntax: expr) ?? .any,
			environment: env,
			wrapped: expr.cast(ReturnStmtSyntax.self),
			valueAnalyzed: valueAnalyzed as? any AnalyzedExpr
		)
	}

	public func visit(_ expr: ParamsExprSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		AnalyzedParamsExpr(
			inferenceType: .void,
			wrapped: expr.cast(ParamsExprSyntax.self),
			paramsAnalyzed: expr.params.enumerated().map { _, param in
				AnalyzedParam(
					type: context.inferenceContext.lookup(syntax: param) ?? .any,
					wrapped: param.cast(ParamSyntax.self),
					environment: context
				)
			},
			environment: context
		)
	}

	public func visit(_ expr: WhileStmtSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		// TODO: Validate condition is bool
		let condition = try castToAnyAnalyzedExpr(expr.condition.accept(self, context))
		let body = try cast(visit(expr.body.cast(BlockStmtSyntax.self), context.withExitBehavior(.pop)), to: AnalyzedBlockStmt.self)

		return AnalyzedWhileStmt(
			inferenceType: body.inferenceType,
			wrapped: expr.cast(WhileStmtSyntax.self),
			conditionAnalyzed: condition,
			bodyAnalyzed: body,
			environment: context
		)
	}

	public func visit(_ stmt: BlockStmtSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		var bodyAnalyzed: [any AnalyzedSyntax] = []

		for bodyExpr in stmt.stmts {
			try bodyAnalyzed.append(bodyExpr.accept(self, context))
		}

		return AnalyzedBlockStmt(
			wrapped: stmt.cast(BlockStmtSyntax.self),
			inferenceType: context.inferenceContext.lookup(syntax: stmt) ?? .any,
			stmtsAnalyzed: bodyAnalyzed,
			environment: context
		)
	}

	public func visit(_ expr: ParamSyntax, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		AnalyzedParam(
			type: context.inferenceContext.lookup(syntax: expr) ?? .any,
			wrapped: expr,
			environment: context
		)
	}

	public func visit(_ expr: GenericParamsSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		AnalyzedGenericParams(
			wrapped: expr,
			environment: context,
			inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
			paramsAnalyzed: expr.params.map {
				AnalyzedGenericParam(wrapped: $0)
			}
		)
	}

	public func visit(_ expr: StructDeclSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		try StructDeclAnalyzer(decl: expr, visitor: self, context: context).analyze()
	}

	// FIXME: I think a lot of this is unnecessary now that we have TypeChecker
	public func visit(_ expr: DeclBlockSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		var declsAnalyzed: [any AnalyzedExpr] = []

		// Do a first pass over the body decls so we have a basic idea of what's available in
		// this struct.
		for decl in expr.decls {
			let analyzed = try decl.accept(self, context)
			guard let declAnalyzed = analyzed as? any AnalyzedDecl else {
				throw AnalyzerError.unexpectedCast(expected: "any AnalyzedDecl", received: analyzed.description)
			}

			declsAnalyzed.append(declAnalyzed)
		}

		guard let declsAnalyzed = declsAnalyzed as? [any AnalyzedDecl] else {
			throw AnalyzerError.unexpectedCast(expected: "[any AnalyzedDecl]", received: "\(declsAnalyzed)")
		}

		return AnalyzedDeclBlock(
			inferenceType: .void,
			wrapped: expr,
			declsAnalyzed: declsAnalyzed,
			environment: context
		)
	}

	public func visit(_ expr: VarDeclSyntax, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		var symbol: Symbol?
		var isGlobal = false

		// Note we use .lexicalScope instead of .getLexicalScope() here because we only want top level decls to count
		// as properties. If we didn't do this then any locals defined inside methods could be created as properties.
		if let lexicalScope = context.lexicalScope {
			symbol = context.symbolGenerator.property(lexicalScope.type.name, expr.name, source: .internal)
		} else if context.isModuleScope {
			isGlobal = true
			symbol = context.symbolGenerator.value(expr.name, source: .internal)
		}

		context.define(local: expr.name, as: expr, isMutable: true, isGlobal: isGlobal)

		let decl = try AnalyzedVarDecl(
			symbol: symbol,
			// swiftlint:disable force_unwrapping
			inferenceType: expr.value != nil ? (context.inferenceContext.lookup(syntax: expr.value!) ?? .void) : .void,
			// swiftlint:enable force_unwrapping
			wrapped: expr,
			analysisErrors: errors(for: expr, in: context.inferenceContext),
			valueAnalyzed: expr.value?.accept(self, context) as? any AnalyzedExpr,
			environment: context
		)

		return decl
	}

	public func visit(_ expr: LetDeclSyntax, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		var symbol: Symbol?
		var isGlobal = false

		// Note we use .lexicalScope instead of .getLexicalScope() here because we only want top level decls to count
		// as properties. If we didn't do this then any locals defined inside methods could be created as properties.
		if let lexicalScope = context.lexicalScope {
			symbol = context.symbolGenerator.property(lexicalScope.type.name, expr.name, source: .internal)
		} else if context.isModuleScope {
			isGlobal = true
			symbol = context.symbolGenerator.value(expr.name, source: .internal)
		}

		context.define(local: expr.name, as: expr, isMutable: false, isGlobal: isGlobal)

		let decl = try AnalyzedLetDecl(
			symbol: symbol,
			// swiftlint:disable force_unwrapping
			inferenceType: expr.value != nil ? (context.inferenceContext.lookup(syntax: expr.value!) ?? .void) : .void,
			// swiftlint:enable force_unwrapping
			wrapped: expr,
			analysisErrors: errors(for: expr, in: context.inferenceContext),
			valueAnalyzed: expr.value?.accept(self, context) as? any AnalyzedExpr,
			environment: context
		)

		return decl
	}

	public func visit(_ expr: IfStmtSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		let alternativeAnalyzed: (any AnalyzedExpr)? = if let alternative = expr.alternative {
			try castToAnyAnalyzedExpr(alternative.accept(self, context))
		} else {
			nil
		}

		return try AnalyzedIfStmt(
			wrapped: expr,
			inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
			environment: context,
			conditionAnalyzed: castToAnyAnalyzedExpr(expr.condition.accept(self, context)),
			consequenceAnalyzed: castToAnyAnalyzedExpr(expr.consequence.accept(self, context)),
			alternativeAnalyzed: alternativeAnalyzed
		)
	}

	public func visit(_ expr: StructExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		AnalyzedErrorSyntax(
			typeID: .void,
			wrapped: ParseErrorSyntax(
				location: expr.location,
				message: "TODO",
				expectation: .none
			),
			environment: context
		)
	}

	public func visit(_ expr: ArrayLiteralExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		let exprsAnalyzed = try expr.exprs.map { try $0.accept(self, context) }

		return try AnalyzedArrayLiteralExpr(
			environment: context,
			exprsAnalyzed: cast(exprsAnalyzed, to: [any AnalyzedExpr].self),
			wrapped: expr,
			inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
			analysisErrors: []
		)
	}

	public func visit(_ expr: SubscriptExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		try SubscriptExprAnalyzer(expr: expr, visitor: self, context: context).analyze()
	}

	public func visit(_ expr: DictionaryLiteralExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		let elementsAnalyzed = try expr.elements.map {
			try cast($0.accept(self, context), to: AnalyzedDictionaryElementExpr.self)
		}

		return AnalyzedDictionaryLiteralExpr(
			elementsAnalyzed: elementsAnalyzed,
			wrapped: expr,
			inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
			environment: context
		)
	}

	public func visit(_ expr: DictionaryElementExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		let key = try castToAnyAnalyzedExpr(expr.key.accept(self, context))
		let value = try castToAnyAnalyzedExpr(expr.value.accept(self, context))
		return AnalyzedDictionaryElementExpr(
			keyAnalyzed: key,
			valueAnalyzed: value,
			wrapped: expr,
			inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
			environment: context
		)
	}

	public func visit(_ expr: ProtocolDeclSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		guard let type = context.inferenceContext.lookup(syntax: expr) else {
			return error(at: expr, "Could not determine type of \(expr)", environment: context)
		}

		guard let body = try visit(expr.body, context) as? AnalyzedProtocolBodyDecl else {
			return error(at: expr, "Invalid body type for \(expr)", environment: context)
		}

		return AnalyzedProtocolDecl(bodyAnalyzed: body, wrapped: expr, inferenceType: type, environment: context)
	}

	public func visit(_ expr: ProtocolBodyDeclSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		guard let type = context.inferenceContext.lookup(syntax: expr) else {
			return error(at: expr, "Could not determine type of \(expr)", environment: context)
		}

		let decls = try expr.decls.map {
			guard let decl = try $0.accept(self, context) as? any AnalyzedDecl else {
				throw AnalyzerError.unexpectedCast(expected: "AnalyzedDecl", received: "\($0)")
			}

			return decl
		}

		return AnalyzedProtocolBodyDecl(wrapped: expr, declsAnalyzed: decls, inferenceType: type, environment: context)
	}

	public func visit(_ expr: FuncSignatureDeclSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		guard let type = context.inferenceContext.lookup(syntax: expr) else {
			return error(at: expr, "Could not determine type of \(expr)", environment: context)
		}

		return AnalyzedFuncSignatureDecl(wrapped: expr, inferenceType: type, environment: context)
	}

	public func visit(_ expr: EnumDeclSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		guard let type = context.inferenceContext.lookup(syntax: expr),
		      case let .instantiatable(enumType as EnumType) = type
		else {
			return error(at: expr, "Could not determine type of \(expr)", environment: context)
		}

		let analysisEnumType = AnalysisEnum(
			name: expr.nameToken.lexeme,
			methods: [:]
		)

		let bodyContext = context.addLexicalScope(for: analysisEnumType)

		bodyContext.define(
			local: "self",
			as: AnalyzedVarExpr(
				inferenceType: type,
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
			type: type,
			isMutable: false
		)

		let analyzedBody = try cast(expr.body.accept(self, bodyContext), to: AnalyzedDeclBlock.self)

		var cases: [AnalyzedEnumCaseDecl] = []
		for decl in analyzedBody.declsAnalyzed {
			if let decl = decl as? AnalyzedEnumCaseDecl {
				cases.append(decl)
			} else {
				_ = try decl.accept(self, bodyContext)
				if let decl = decl as? FuncExpr,
				   let name = decl.name?.lexeme,
				   case let .function(params, returns) = context.inferenceContext.lookup(syntax: decl)
				{
					analysisEnumType.methods[name] = Method(
						name: name,
						symbol: context.symbolGenerator.method(enumType.name, name, parameters: params.map(\.description), source: .internal),
						params: params,
						inferenceType: .function(params, returns),
						location: decl.location,
						returnTypeID: returns
					)
				}
			}
		}

		context.define(type: expr.nameToken.lexeme, as: analysisEnumType)

		return AnalyzedEnumDecl(
			wrapped: expr,
			symbol: context.symbolGenerator.enum(expr.nameToken.lexeme, source: .internal),
			analysisEnum: analysisEnumType,
			casesAnalyzed: cases,
			inferenceType: type,
			environment: context,
			bodyAnalyzed: analyzedBody
		)
	}

	public func visit(_ expr: EnumCaseDeclSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		guard let type = context.inferenceContext.lookup(syntax: expr),
		      case let .enumCase(enumCase) = type
		else {
			return error(at: expr, "Could not determine type of \(expr)", environment: context)
		}

		return try AnalyzedEnumCaseDecl(
			wrapped: expr,
			enumName: enumCase.type.name,
			attachedTypesAnalyzed: expr.attachedTypes.map { try cast($0.accept(self, context), to: AnalyzedTypeExpr.self) },
			inferenceType: type,
			environment: context
		)
	}

	public func visit(_ expr: MatchStatementSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		guard let type = context.inferenceContext.lookup(syntax: expr) else {
			return error(at: expr, "Could not determine type of match case: \(expr)", environment: context)
		}

		var hasDefault = false
		let targetAnalyzed = try castToAnyAnalyzedExpr(expr.target.accept(self, context))
		let casesAnalyzed = try expr.cases.map {
			let result = try cast($0.accept(self, context), to: AnalyzedCaseStmt.self)

			if result.isDefault {
				hasDefault = true
			}

			return result
		}
		var errors: [AnalysisError] = []

		if case let .instantiatable(type as EnumType) = targetAnalyzed.inferenceType, !hasDefault {
			// Check that all enum cases are specified
			let specifiedCases: [String] = casesAnalyzed.compactMap {
				guard case let .pattern(pattern) = $0.patternAnalyzed?.inferenceType else {
					return nil
				}

				guard case let .enumCase(kase) = pattern.type else {
					return nil
				}

				return kase.name
			}

			var missingCases: [String] = []

			for kase in type.cases {
				if !specifiedCases.contains(kase.name) {
					missingCases.append(kase.name)
				}
			}

			if !missingCases.isEmpty {
				errors.append(.init(kind: .matchNotExhaustive("Match not exhaustive. Missing \(missingCases.joined(separator: ", "))"), location: expr.location))
			}
		} else if case .base(.bool) = targetAnalyzed.inferenceType, !hasDefault {
			let specifiedCases: [Bool] = casesAnalyzed.compactMap {
				guard let kase = $0.patternAnalyzed as? AnalyzedLiteralExpr, case let .bool(bool) = kase.value else {
					return nil
				}

				return bool
			}

			if !specifiedCases.contains(true) || !specifiedCases.contains(false) {
				errors.append(.init(kind: .matchNotExhaustive("Match not exhaustive."), location: expr.location))
			}
		} else if !hasDefault {
			errors.append(.init(kind: .matchNotExhaustive("Match not exhaustive."), location: expr.location))
		}

		return AnalyzedMatchStatement(
			wrapped: expr,
			targetAnalyzed: targetAnalyzed,
			casesAnalyzed: casesAnalyzed,
			inferenceType: type,
			environment: context,
			analysisErrors: errors
		)
	}

	public func visit(_ expr: CaseStmtSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		if expr.patternSyntax == nil {
			// It's an `else` clause
			return try AnalyzedCaseStmt(
				wrapped: expr,
				patternAnalyzed: nil,
				bodyAnalyzed: expr.body.map {
					let stmt = try $0.accept(self, context)

					if let stmt = stmt as? any AnalyzedStmt {
						return stmt
					} else {
						throw AnalyzerError.unexpectedCast(expected: "any AnalyzedStmt", received: "\(Swift.type(of: stmt))")
					}
				},
				pattern: .void,
				inferenceType: .void,
				environment: context
			)
		}

		guard let type = context.inferenceContext.lookup(syntax: expr),
		      let patternSyntax = expr.patternSyntax,
		      let pattern = context.inferenceContext.lookup(syntax: patternSyntax)
		else {
			return error(at: expr, "Could not determine type of match case: \(expr)", environment: context)
		}

		let patternAnalyzed = try castToAnyAnalyzedExpr(patternSyntax.accept(self, context))
		let bodyAnalyzed = try expr.body.map {
			let stmt = try $0.accept(self, context)

			if let stmt = stmt as? any AnalyzedStmt {
				return stmt
			} else {
				throw AnalyzerError.unexpectedCast(expected: "any AnalyzedStmt", received: "\(Swift.type(of: stmt))")
			}
		}

		var variables: [String: InferenceType] = [:]
		if case let .pattern(pattern) = context.inferenceContext.lookup(syntax: patternAnalyzed) {
			for case let .variable(name, type) in pattern.arguments {
				variables[name] = type
			}
		}

		return AnalyzedCaseStmt(
			wrapped: expr,
			patternAnalyzed: patternAnalyzed,
			bodyAnalyzed: bodyAnalyzed,
			pattern: pattern,
			inferenceType: type,
			environment: context
		)
	}

	public func visit(_ expr: EnumMemberExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		error(at: expr, "TODO", environment: context, expectation: .none)
	}

	public func visit(_ expr: InterpolatedStringExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		guard let type = context.inferenceContext.lookup(syntax: expr) else {
			return error(at: expr, "Could not find type for \(expr)", environment: context)
		}

		return try AnalyzedInterpolatedStringExpr(
			wrapped: expr,
			segmentsAnalyzed: expr.segments.map {
				switch $0 {
				case let .string(string, token):
					.string(string, token)
				case let .expr(interpolation):
					try .expr(
						.init(
							exprAnalyzed: castToAnyAnalyzedExpr(interpolation.expr.accept(self, context)),
							startToken: interpolation.startToken,
							endToken: interpolation.endToken
						)
					)
				}
			},
			inferenceType: type,
			environment: context
		)
	}

	public func visit(_ expr: ForStmtSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		#warning("TODO")
		return error(at: expr, "TODO", environment: context, expectation: .none)
	}

	// GENERATOR_INSERTION
}
