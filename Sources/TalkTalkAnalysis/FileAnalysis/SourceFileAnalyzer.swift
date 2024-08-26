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
		let exprAnalyzed = try expr.expr.accept(self, context) as! any AnalyzedExpr

		return AnalyzedExprStmt(
			wrapped: expr.cast(ExprStmtSyntax.self),
			exprAnalyzed: exprAnalyzed,
			exitBehavior: context.exprStmtExitBehavior,
			environment: context
		)
	}

	public func visit(_ expr: ImportStmtSyntax, _ context: Environment) -> SourceFileAnalyzer.Value {
		AnalyzedImportStmt(
			environment: context,
			typeID: TypeID(.none),
			wrapped: expr.cast(ImportStmtSyntax.self)
		)
	}

	public func visit(_ expr: IdentifierExprSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		AnalyzedIdentifierExpr(
			typeID: TypeID(),
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
				typeID: TypeID(.bool),
				exprAnalyzed: exprAnalyzed as! any AnalyzedExpr,
				environment: context,
				wrapped: expr.cast(UnaryExprSyntax.self)
			)
		case .minus:
			return AnalyzedUnaryExpr(
				typeID: TypeID(.int),
				exprAnalyzed: exprAnalyzed as! any AnalyzedExpr,
				environment: context,
				wrapped: expr.cast(UnaryExprSyntax.self)
			)
		default:
			fatalError("unreachable")
		}
	}

	public func visit(_ expr: CallArgument, _ context: Environment) throws -> any AnalyzedSyntax {
		try AnalyzedArgument(
			environment: context,
			label: expr.label,
			wrapped: expr.cast(CallArgument.self),
			expr: expr.value.accept(self, context) as! any AnalyzedExpr
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
		let value = try expr.value.accept(self, context) as! any AnalyzedExpr
		let receiver = try expr.receiver.accept(self, context) as! any AnalyzedExpr

		let errors = checkAssignment(to: receiver, value: value, in: context)

		// if errors.isEmpty {
		// switch receiver {
		// 	case let receiver as AnalyzedVarExpr:
		// 		context.define(local: receiver.name, as: value, isMutable: receiver.isMutable)
		// 	default: ()
		// 	}
		// }

		return AnalyzedDefExpr(
			typeID: TypeID(value.typeAnalyzed),
			wrapped: expr.cast(DefExprSyntax.self),
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
			typeID: TypeID(.error(expr.message)),
			wrapped: expr.cast(ParseErrorSyntax.self),
			environment: context
		)
	}

	public func visit(_ expr: LiteralExprSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		let typeID = switch expr.value {
		case .int:
			TypeID(.int)
		case .bool:
			TypeID(.bool)
		case .none:
			TypeID(.none)
		case .string:
			TypeID(.instance(.struct("String", [:])))
		}

		if typeID.current == .instance(.struct("String", [:])) {
			_ = context.lookupStruct(named: "String")
		}

		if typeID.current == .instance(.struct("Int", [:])) {
			_ = context.lookupStruct(named: "Int")
		}

		return AnalyzedLiteralExpr(
			typeID: typeID,
			wrapped: expr.cast(LiteralExprSyntax.self),
			environment: context
		)
	}

	public func visit(_ expr: VarExprSyntax, _ context: Environment) throws -> Value {
		if let binding = context.lookup(expr.name) {
			var symbol: Symbol? = nil

			if case let .struct(name) = binding.type.current {
				if let module = binding.externalModule {
					symbol = module.structs[name]!.symbol
				} else {
					symbol = context.symbolGenerator.struct(expr.name, source: .internal)
				}
			} else if case let .function(name, _, _, _) = binding.type.current {
				if let module = binding.externalModule {
					symbol = module.moduleFunction(named: name)!.symbol
				} else if binding.isGlobal {
					symbol = context.symbolGenerator.value(expr.name, source: .internal)
				}
			} else {
				if let module = binding.externalModule {
					symbol = module.values[expr.name]!.symbol
				} else {
					if binding.isGlobal {
						symbol = context.symbolGenerator.value(expr.name, source: .internal, namespace: [])
					}
				}
			}

			return AnalyzedVarExpr(
				typeID: binding.type,
				wrapped: expr.cast(VarExprSyntax.self),
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
			typeID: TypeID(.any),
			wrapped: expr.cast(VarExprSyntax.self),
			symbol: context.symbolGenerator.value(expr.name, source: .internal),
			environment: context,
			analysisErrors: errors,
			isMutable: false
		)
	}

	public func visit(_ expr: BinaryExprSyntax, _ env: Environment) throws -> SourceFileAnalyzer.Value {
		let lhs = try expr.lhs.accept(self, env) as! any AnalyzedExpr
		let rhs = try expr.rhs.accept(self, env) as! any AnalyzedExpr

		if lhs.typeID.current == .pointer,
		   [.int, .placeholder].contains(rhs.typeID.current)
		{
			// This is pointer arithmetic
			// TODO: More generic handling of different operand types
			rhs.typeID.update(.int, location: expr.location)
		} else {
			infer([lhs, rhs], in: env)
		}

		return AnalyzedBinaryExpr(
			typeID: lhs.typeID,
			wrapped: expr.cast(BinaryExprSyntax.self),
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
			typeID: expr.consequence.accept(self, context).typeID,
			wrapped: expr.cast(IfExprSyntax.self),
			conditionAnalyzed: expr.condition.accept(self, context) as! any AnalyzedExpr,
			consequenceAnalyzed: visit(expr.consequence.cast(BlockStmtSyntax.self), context) as! AnalyzedBlockStmt,
			alternativeAnalyzed: visit(expr.alternative.cast(BlockStmtSyntax.self), context) as! AnalyzedBlockStmt,
			environment: context,
			analysisErrors: errors
		)
	}

	public func visit(_ expr: TypeExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
//		guard let type = context.type(named: expr.identifier.lexeme) else {
//			return error(at: expr, "No type found named: \(expr.identifier.lexeme)", environment: context, expectation: .type)
//		}

		if let type = context.type(named: expr.identifier.lexeme) {
			if type.primitive != nil {
				return AnalyzedTypeExpr(
					wrapped: expr.cast(TypeExprSyntax.self),
					symbol: .primitive(type.description),
					typeID: TypeID(type),
					environment: context
				)
			}

			if case let .generic(valueType, string) = type {
				return AnalyzedTypeExpr(
					wrapped: expr.cast(TypeExprSyntax.self),
					symbol: context.symbolGenerator.generic(expr.identifier.lexeme, source: .internal),
					typeID: TypeID(.generic(valueType, expr.identifier.lexeme)),
					environment: context
				)
			}

			return AnalyzedTypeExpr(
				wrapped: expr.cast(TypeExprSyntax.self),
				symbol: context.symbolGenerator.struct(expr.identifier.lexeme, source: .internal),
				typeID: TypeID(type),
				environment: context
			)
		}

		return error(at: expr, "No type found for type expr named: \(expr.identifier.lexeme)", environment: context, expectation: .type)
	}

	public func visit(_ expr: FuncExprSyntax, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		try FuncExprAnalyzer(expr: expr, visitor: self, context: context).analyze()
	}

	public func visit(_ expr: InitDeclSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		let paramsAnalyzed = try expr.params.accept(self, context) as! AnalyzedParamsExpr

		let innerEnvironment = context.add(namespace: "init")
		for param in paramsAnalyzed.paramsAnalyzed {
			innerEnvironment.define(parameter: param.name, as: param)
		}

		let bodyAnalyzed = try expr.body.accept(self, innerEnvironment)

		guard let lexicalScope = innerEnvironment.getLexicalScope() else {
			return error(at: expr, "Could not determine lexical scope for init", environment: context, expectation: .none)
		}

		return AnalyzedInitDecl(
			wrapped: expr.cast(InitDeclSyntax.self),
			symbol: context.symbolGenerator.method(lexicalScope.scope.name!, "init", parameters: paramsAnalyzed.paramsAnalyzed.map(\.name), source: .internal),
			typeID: TypeID(.struct(lexicalScope.scope.name!)),
			environment: innerEnvironment,
			parametersAnalyzed: paramsAnalyzed,
			bodyAnalyzed: bodyAnalyzed as! AnalyzedDeclBlock
		)
	}

	public func visit(_ expr: ReturnStmtSyntax, _ env: Environment) throws -> SourceFileAnalyzer.Value {
		let valueAnalyzed = try expr.value?.accept(self, env)
		return AnalyzedReturnStmt(
			typeID: TypeID(valueAnalyzed?.typeAnalyzed ?? .void),
			environment: env,
			wrapped: expr.cast(ReturnStmtSyntax.self),
			valueAnalyzed: valueAnalyzed as? any AnalyzedExpr
		)
	}

	public func visit(_ expr: ParamsExprSyntax, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		try AnalyzedParamsExpr(
			typeID: TypeID(.void),
			wrapped: expr.cast(ParamsExprSyntax.self),
			paramsAnalyzed: expr.params.enumerated().map { _, param in
				var type = TypeID()

				if let paramType = param.type {
					let analyzedTypeExpr = try visit(paramType.cast(TypeExprSyntax.self), context)
					type = analyzedTypeExpr.typeID.asInstance(in: context, location: param.location)
				}

				return AnalyzedParam(
					type: type,
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
		let condition = try expr.condition.accept(self, context) as! any AnalyzedExpr
		let body = try visit(expr.body.cast(BlockStmtSyntax.self), context.withExitBehavior(.pop)) as! AnalyzedBlockStmt

		return AnalyzedWhileStmt(
			typeID: body.typeID,
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
			typeID: TypeID(bodyAnalyzed.last?.typeAnalyzed ?? .none),
			stmtsAnalyzed: bodyAnalyzed,
			environment: context
		)
	}

	public func visit(_ expr: ParamSyntax, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		AnalyzedParam(
			type: TypeID(),
			wrapped: expr as! ParamSyntax,
			environment: context
		)
	}

	public func visit(_ expr: GenericParamsSyntax, _ environment: Environment) throws -> any AnalyzedSyntax {
		AnalyzedGenericParams(
			wrapped: expr as! GenericParamsSyntax,
			environment: environment,
			typeID: TypeID(),
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

			// If we have an updated type for a method, update the struct to know about it.
			if let funcExpr = declAnalyzed as? AnalyzedFuncExpr,
			   let lexicalScope = context.lexicalScope,
			   let name = funcExpr.name?.lexeme,
			   let existing = lexicalScope.scope.methods[name]
			{
				lexicalScope.scope.add(
					method: Method(
						symbol: funcExpr.symbol,
						name: funcExpr.name!.lexeme,
						slot: existing.slot,
						params: funcExpr.analyzedParams.paramsAnalyzed,
						typeID: funcExpr.typeID,
						returnTypeID: funcExpr.returnType,
						expr: funcExpr,
						isMutable: false
					))
			}
		}

		return AnalyzedDeclBlock(
			typeID: TypeID(.void),
			wrapped: expr as! DeclBlockSyntax,
			declsAnalyzed: declsAnalyzed as! [any AnalyzedDecl],
			environment: context
		)
	}

	public func visit(_ expr: VarDeclSyntax, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		var errors: [AnalysisError] = []

		if let existing = context.local(named: expr.name),
		   let definition = existing.definition,
		   definition.location.start != expr.location.start,
		   context.shouldReportErrors
		{
			errors.append(
				.init(
					kind: .invalidRedeclaration(variable: expr.name, existing: existing),
					location: expr.location
				)
			)
		}

		let type = context.type(named: expr.typeExpr?.identifier.lexeme, asInstance: true) ?? .error("Could not find type named: \(expr.typeExpr?.identifier.lexeme ?? "<no name>")")
		var valueType = TypeID(type)
		let value = try expr.value?.accept(self, context) as? any AnalyzedExpr
		if let value, valueType.current == .placeholder {
			valueType.infer(from: value.typeID)
		}

		if case .error = valueType.current, context.shouldReportErrors {
			errors.append(
				.init(
					kind: .typeNotFound(expr.typeExpr?.description ?? "<no type name>"),
					location: [expr.typeExpr?.location.start ?? expr.location.start]
				)
			)
		}

		// We use `lexicalScope` here instead of `getLexicalScope` because we only want to generate symbols for properties,
		// not locals inside methods.
		var isGlobal = false
		var symbol: Symbol?
		if let scope = context.lexicalScope {
			symbol = context.symbolGenerator.property(scope.scope.name ?? scope.expr.description, expr.name, source: .internal)
		} else if context.isModuleScope {
			isGlobal = true
			symbol = context.symbolGenerator.value(expr.name, source: .internal)
		}

		let decl = AnalyzedVarDecl(
			symbol: symbol,
			typeID: valueType,
			wrapped: expr as! VarDeclSyntax,
			analysisErrors: errors,
			valueAnalyzed: value,
			environment: context
		)

		if let value {
			context.define(local: expr.name, as: value, definition: decl, isMutable: true, isGlobal: isGlobal)
		}

		return decl
	}

	public func visit(_ expr: LetDeclSyntax, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		var errors: [AnalysisError] = []
		let type = TypeID(context.type(named: expr.typeExpr?.identifier.lexeme) ?? .error("Could not find type from \(expr)"))

		if let existing = context.local(named: expr.name),
		   let definition = existing.definition,
		   definition.location.start != expr.location.start
		{
			errors.append(
				.init(
					kind: .invalidRedeclaration(variable: expr.name, existing: existing),
					location: expr.location
				)
			)
		}

		if case .error = type.current {
			errors.append(
				.init(
					kind: .typeNotFound(expr.typeExpr?.description ?? "<no type name>"),
					location: [expr.typeExpr?.location.start ?? expr.location.start]
				)
			)
		}

		var valueType = type
		let value = try expr.value?.accept(self, context) as? any AnalyzedExpr
		if let value, valueType.current == .placeholder {
			valueType = value.typeID
		}

		// We use `lexicalScope` here instead of `getLexicalScope` because we only want to generate symbols for properties,
		// not locals inside methods.
		var isGlobal = false
		var symbol: Symbol?
		if let scope = context.lexicalScope {
			symbol = context.symbolGenerator.property(scope.scope.name ?? scope.expr.description, expr.name, source: .internal)
		} else if context.isModuleScope {
			isGlobal = true
			symbol = context.symbolGenerator.value(expr.name, source: .internal)
		}

		let decl = AnalyzedLetDecl(
			symbol: symbol,
			typeID: valueType,
			wrapped: expr as! LetDeclSyntax,
			analysisErrors: errors,
			valueAnalyzed: value,
			environment: context
		)

		if let value {
			context.define(local: expr.name, as: value, definition: decl, isMutable: false, isGlobal: isGlobal)
		}

		return decl
	}

	public func visit(_ expr: IfStmtSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		try AnalyzedIfStmt(
			wrapped: expr as! IfStmtSyntax,
			typeID: TypeID(.void),
			environment: context,
			conditionAnalyzed: expr.condition.accept(self, context) as! any AnalyzedExpr,
			consequenceAnalyzed: expr.consequence.accept(self, context) as! any AnalyzedExpr,
			alternativeAnalyzed: expr.alternative?.accept(self, context) as? any AnalyzedExpr
		)
	}

	public func visit(_ expr: StructExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		AnalyzedErrorSyntax(
			typeID: TypeID(.error("TODO")),
			wrapped: ParseErrorSyntax(
				location: expr.location,
				message: "TODO",
				expectation: .none
			),
			environment: context
		)
	}

	public func visit(_ expr: ArrayLiteralExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		let elements = try expr.exprs.map { try $0.accept(self, context) }
		let elementType = elements.map(\.typeID).first ?? TypeID(.placeholder)
		let instanceType = InstanceValueType(ofType: .struct("Array"), boundGenericTypes: ["Element": elementType])

		var errors: [AnalysisError] = []
		if elements.count > 255 {
			errors.append(.init(kind: .expressionCount("Array literals can only have 255 elements"), location: expr.location))
		}

		return AnalyzedArrayLiteralExpr(
			environment: context,
			exprsAnalyzed: elements as! [any AnalyzedExpr],
			wrapped: expr as! ArrayLiteralExprSyntax,
			typeID: TypeID(.instance(instanceType)),
			analysisErrors: errors
		)
	}

	public func visit(_ expr: SubscriptExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		try SubscriptExprAnalyzer(expr: expr, visitor: self, context: context).analyze()
	}

	public func visit(_ expr: DictionaryLiteralExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		let elementsAnalyzed = try expr.elements.map { try $0.accept(self, context) } as! [AnalyzedDictionaryElementExpr]

		let keyType = TypeID()
		let valueType = TypeID()

		for element in elementsAnalyzed {
			// TODO: Handle heterogenous types
			keyType.update(element.keyAnalyzed.typeID.current, location: expr.location)
			valueType.update(element.valueAnalyzed.typeID.current, location: expr.location)
		}

		let instance = InstanceValueType(
			ofType: .struct("Dictionary"),
			boundGenericTypes: [
				"Key": keyType,
				"Value": valueType
			]
		)

		return AnalyzedDictionaryLiteralExpr(
			elementsAnalyzed: elementsAnalyzed,
			wrapped: expr as! DictionaryLiteralExprSyntax,
			typeID: TypeID(.instance(instance)),
			environment: context
		)
	}

	public func visit(_ expr: DictionaryElementExprSyntax, _ context: Environment) throws -> any AnalyzedSyntax {
		let key = try expr.key.accept(self, context) as! any AnalyzedExpr
		let value = try expr.value.accept(self, context) as! any AnalyzedExpr
		return AnalyzedDictionaryElementExpr(
			keyAnalyzed: key,
			valueAnalyzed: value,
			wrapped: expr as! DictionaryElementExprSyntax,
			typeID: TypeID(),
			environment: context
		)
	}

	// GENERATOR_INSERTION
}
