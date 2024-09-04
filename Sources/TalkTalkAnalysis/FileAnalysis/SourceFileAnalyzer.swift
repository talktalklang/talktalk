//
//  Analyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//
import Foundation
import TalkTalkBytecode
import TalkTalkSyntax

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

		return AnalyzedExprStmt(
			wrapped: try cast(expr, to: ExprStmtSyntax.self),
			exprAnalyzed: try castToAnyAnalyzedExpr(exprAnalyzed),
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

			return AnalyzedUnaryExpr(
				inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
				exprAnalyzed: try castToAnyAnalyzedExpr(exprAnalyzed),
				environment: context,
				wrapped: expr.cast(UnaryExprSyntax.self)
			)
		case .minus:
			return AnalyzedUnaryExpr(
				inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
				exprAnalyzed: try castToAnyAnalyzedExpr(exprAnalyzed),
				environment: context,
				wrapped: expr.cast(UnaryExprSyntax.self)
			)
		default:
			throw AnalyzerError.typeNotInferred("")
		}
	}

	public func visit(_ expr: CallArgument, _ context: Environment) throws -> any AnalyzedSyntax {
		AnalyzedArgument(
			environment: context,
			label: expr.label,
			wrapped: expr.cast(CallArgument.self),
			expr: try castToAnyAnalyzedExpr(expr.value.accept(self, context))
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

		return AnalyzedDefExpr(
			inferenceType: .void,
			wrapped: try cast(expr, to: DefExprSyntax.self),
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

		guard let type =  context.inferenceContext.lookup(syntax: expr) else {
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

			if case let .structType(type) = binding.type {
				if let module = binding.externalModule {
					symbol = module.structs[type.name]?.symbol
					guard symbol != nil else {
						throw AnalyzerError.symbolNotFound("expected symbol for struct: \(type.name)")
					}
				} else {
					symbol = context.symbolGenerator.struct(expr.name, source: .internal)
				}
			} else if case .function(_, _) = binding.type {
				if let module = binding.externalModule {
					symbol = module.moduleFunction(named: binding.name)?.symbol
					guard symbol != nil else {
						throw AnalyzerError.symbolNotFound("expected symbol for external function: \(binding.name)")
					}
				} else if binding.isGlobal {
					symbol = context.symbolGenerator.value(expr.name, source: .internal)
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

			return AnalyzedVarExpr(
				inferenceType: binding.type,
				wrapped: try cast(expr, to: VarExprSyntax.self),
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

		return AnalyzedBinaryExpr(
			inferenceType: env.inferenceContext.lookup(syntax: expr) ?? .any,
			wrapped: try cast(expr, to: BinaryExprSyntax.self),
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
					location: expr.consequence.stmts[expr.consequence.stmts.count-1].location
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
					location: expr.alternative.stmts[expr.alternative.stmts.count-1].location
				)
			)
		}

		// We always want if exprs to be able to return their value
		let context = context.withExitBehavior(.none)

		// TODO: Error if the branches don't match or condition isn't a bool
		return try AnalyzedIfExpr(
			inferenceType: expr.consequence.accept(self, context).inferenceType,
			wrapped: expr.cast(IfExprSyntax.self),
			conditionAnalyzed: try castToAnyAnalyzedExpr(expr.condition.accept(self, context)),
			consequenceAnalyzed: try cast(visit(expr.consequence.cast(BlockStmtSyntax.self), context), to: AnalyzedBlockStmt.self),
			alternativeAnalyzed: try cast(visit(expr.alternative.cast(BlockStmtSyntax.self), context), to: AnalyzedBlockStmt.self),
			environment: context,
			analysisErrors: errors
		)
	}

	public func visit(_ expr: TypeExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		let symbol: Symbol

		switch context.inferenceContext.lookup(syntax: expr) {
		case .typeVar(_):
			symbol = context.symbolGenerator.generic(expr.identifier.lexeme, source: .internal)
		case .base(let type):
			symbol = .primitive("\(type)")
		case .structType(_):
			symbol = context.symbolGenerator.struct(expr.identifier.lexeme, source: .internal)
		default:
			symbol = context.symbolGenerator.generic("error", source: .internal)
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
			symbol: context.symbolGenerator.method(lexicalScope.scope.name ?? "<no name>", "init", parameters: paramsAnalyzed.paramsAnalyzed.map(\.name), source: .internal),
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
				return AnalyzedParam(
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
			guard let declAnalyzed = try decl.accept(self, context) as? any AnalyzedDecl else {
				continue
			}

			declsAnalyzed.append(declAnalyzed)

//			// If we have an updated type for a method, update the struct to know about it.
//			if let funcExpr = declAnalyzed as? AnalyzedFuncExpr,
//				 let lexicalScope = context.lexicalScope,
//				 let name = funcExpr.name?.lexeme,
//				 let existing = lexicalScope.scope.methods[name]
//			{
//				lexicalScope.scope.add(
//					method: Method(
//						name: funcExpr.name!.lexeme,
//						slot: existing.slot,
//						params: funcExpr.analyzedParams.paramsAnalyzed.map(\.typeAnalyzed),
//						inferenceType: context.inferenceContext.lookup(syntax: funcExpr) ?? .any,
//						location: funcExpr.semanticLocation ?? funcExpr.location,
//						returnTypeID: funcExpr.returnType,
//						isMutable: false
//					))
//			}
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
		// We use `lexicalScope` here instead of `getLexicalScope` because we only want to generate symbols for properties,
		// not locals inside methods.
		var symbol: Symbol?
		var isGlobal = false
		if let scope = context.lexicalScope {
			symbol = context.symbolGenerator.property(scope.scope.name ?? scope.expr.description, expr.name, source: .internal)
		} else if context.isModuleScope {
			isGlobal = true
			symbol = context.symbolGenerator.value(expr.name, source: .internal)
		}

		context.define(local: expr.name, as: expr, isMutable: true, isGlobal: isGlobal)

		let decl = AnalyzedVarDecl(
			symbol: symbol,
			// swiftlint:disable force_unwrapping
			inferenceType: expr.value != nil ? (context.inferenceContext.lookup(syntax: expr.value!) ?? .void) : .void,
			// swiftlint:enable force_unwrapping
			wrapped: expr,
			analysisErrors: errors(for: expr, in: context.inferenceContext),
			valueAnalyzed: try expr.value?.accept(self, context) as? any AnalyzedExpr,
			environment: context
		)

		return decl
	}

	public func visit(_ expr: LetDeclSyntax, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		// We use `lexicalScope` here instead of `getLexicalScope` because we only want to generate symbols for properties,
		// not locals inside methods.
		var symbol: Symbol?
		var isGlobal = false
		if let scope = context.lexicalScope {
			symbol = context.symbolGenerator.property(scope.scope.name ?? scope.expr.description, expr.name, source: .internal)
		} else if context.isModuleScope {
			isGlobal = true
			symbol = context.symbolGenerator.value(expr.name, source: .internal)
		}

		context.define(local: expr.name, as: expr, isMutable: false, isGlobal: isGlobal)

		let decl = AnalyzedLetDecl(
			symbol: symbol,
			// swiftlint:disable force_unwrapping
			inferenceType: expr.value != nil ? (context.inferenceContext.lookup(syntax: expr.value!) ?? .void) : .void,
			// swiftlint:enable force_unwrapping
			wrapped: expr,
			analysisErrors: errors(for: expr, in: context.inferenceContext),
			valueAnalyzed: try expr.value?.accept(self, context) as? any AnalyzedExpr,
			environment: context
		)

		return decl
	}

	public func visit(_ expr: IfStmtSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		let alternativeAnalyzed: (any AnalyzedExpr)?
		if let alternative = expr.alternative {
			alternativeAnalyzed = try castToAnyAnalyzedExpr(alternative.accept(self, context))
		} else {
			alternativeAnalyzed = nil
		}

		return AnalyzedIfStmt(
			wrapped: expr,
			inferenceType: context.inferenceContext.lookup(syntax: expr) ?? .any,
			environment: context,
			conditionAnalyzed: try castToAnyAnalyzedExpr(expr.condition.accept(self, context)),
			consequenceAnalyzed: try castToAnyAnalyzedExpr(expr.consequence.accept(self, context)),
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

		return AnalyzedArrayLiteralExpr(
			environment: context,
			exprsAnalyzed: try cast(exprsAnalyzed, to: [any AnalyzedExpr].self),
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
		return error(at: expr, "TODO", environment: context, expectation: .none)
	}

	public func visit(_ expr: ProtocolBodyDeclSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		return error(at: expr, "TODO", environment: context, expectation: .none)
	}

	public func visit(_ expr: FuncSignatureDeclSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		return error(at: expr, "TODO", environment: context, expectation: .none)
	}

	// GENERATOR_INSERTION
}
