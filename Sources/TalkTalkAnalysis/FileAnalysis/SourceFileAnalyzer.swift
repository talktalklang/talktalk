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

	public func visit(_ expr: any ExprStmt, _ context: Environment) throws -> any AnalyzedSyntax {
		let exprAnalyzed = try expr.expr.accept(self, context) as! any AnalyzedExpr

		return AnalyzedExprStmt(
			wrapped: expr,
			exprAnalyzed: exprAnalyzed,
			exitBehavior: context.exprStmtExitBehavior,
			environment: context
		)
	}

	public func visit(_ expr: any ImportStmt, _ context: Environment) -> SourceFileAnalyzer.Value {
		AnalyzedImportStmt(
			environment: context,
			typeID: TypeID(.none),
			stmt: expr
		)
	}

	public func visit(_ expr: any IdentifierExpr, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		AnalyzedIdentifierExpr(
			typeID: TypeID(),
			expr: expr,
			environment: context
		)
	}

	public func visit(_ expr: any UnaryExpr, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		let exprAnalyzed = try expr.expr.accept(self, context)

		switch expr.op {
		case .bang:

			return AnalyzedUnaryExpr(
				typeID: TypeID(.bool),
				exprAnalyzed: exprAnalyzed as! any AnalyzedExpr,
				environment: context,
				wrapped: expr
			)
		case .minus:
			return AnalyzedUnaryExpr(
				typeID: TypeID(.int),
				exprAnalyzed: exprAnalyzed as! any AnalyzedExpr,
				environment: context,
				wrapped: expr
			)
		default:
			fatalError("unreachable")
		}
	}

	public func visit(_ expr: CallArgument, _ context: Environment) throws -> any AnalyzedSyntax {
		try AnalyzedArgument(
			environment: context,
			label: expr.label,
			expr: expr.value.accept(self, context) as! any AnalyzedExpr
		)
	}

	public func visit(_ expr: any CallExpr, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		try CallExprAnalyzer(expr: expr, visitor: self, context: context).analyze()
	}

	public func visit(_ expr: any MemberExpr, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		let receiver = try expr.receiver.accept(self, context)
		let propertyName = expr.property

		var member: (any Member)? = nil
		switch receiver.typeAnalyzed {
		case let .instance(instanceType):
			guard case let .struct(name) = instanceType.ofType,
			      let structType = context.lookupStruct(named: name)
			else {
				return error(
					at: expr, "Could not find type of \(instanceType)", environment: context,
					expectation: .identifier
				)
			}

			member = structType.properties[propertyName] ?? structType.methods[propertyName]
		default:
			return error(
				at: expr, "Cannot access property `\(propertyName)` on `\(receiver)` (\(receiver.typeAnalyzed.description))",
				environment: context,
				expectation: .member
			)
		}

		var errors: [AnalysisError] = []
		if member == nil, context.shouldReportErrors {
			errors.append(
				.init(
					kind: .noMemberFound(receiver: receiver, property: propertyName),
					location: receiver.location
				)
			)
		}

		return AnalyzedMemberExpr(
			typeID: member?.typeID ?? TypeID(.error("no member found")),
			expr: expr,
			environment: context,
			receiverAnalyzed: receiver as! any AnalyzedExpr,
			memberAnalyzed: member ?? error(at: expr, "no member found", environment: context, expectation: .member),
			analysisErrors: errors,
			isMutable: member?.isMutable ?? false
		)
	}

	public func visit(_ expr: any DefExpr, _ context: Environment) throws -> SourceFileAnalyzer.Value {
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
			expr: expr,
			receiverAnalyzed: receiver,
			analysisErrors: errors,
			valueAnalyzed: value,
			environment: context
		)
	}

	public func visit(_ expr: any ParseError, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		AnalyzedErrorSyntax(
			typeID: TypeID(.error(expr.message)),
			expr: expr,
			environment: context
		)
	}

	public func visit(_ expr: any LiteralExpr, _ context: Environment) throws
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
			TypeID(.instance(.struct("String")))
		}

		if typeID.current == .instance(.struct("String")) {
			_ = context.lookupStruct(named: "String")
		}

		if typeID.current == .instance(.struct("Int")) {
			_ = context.lookupStruct(named: "Int")
		}

		return AnalyzedLiteralExpr(
			typeID: typeID,
			expr: expr,
			environment: context
		)
	}

	public func visit(_ expr: any VarExpr, _ context: Environment) throws -> Value {
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
				expr: expr,
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
			expr: expr,
			symbol: context.symbolGenerator.value(expr.name, source: .internal),
			environment: context,
			analysisErrors: errors,
			isMutable: false
		)
	}

	public func visit(_ expr: any BinaryExpr, _ env: Environment) throws -> SourceFileAnalyzer.Value {
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
			expr: expr,
			lhsAnalyzed: lhs,
			rhsAnalyzed: rhs,
			environment: env
		)
	}

	public func visit(_ expr: any IfExpr, _ context: Environment) throws -> SourceFileAnalyzer.Value {
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
			expr: expr,
			conditionAnalyzed: expr.condition.accept(self, context) as! any AnalyzedExpr,
			consequenceAnalyzed: visit(expr.consequence, context) as! AnalyzedBlockStmt,
			alternativeAnalyzed: visit(expr.alternative, context) as! AnalyzedBlockStmt,
			environment: context,
			analysisErrors: errors
		)
	}

	public func visit(_ expr: any TypeExpr, _ context: Environment) throws -> any AnalyzedSyntax {
		let type = context.type(named: expr.identifier.lexeme)

		if case let .error(err) = type {
			return error(at: expr, err, environment: context, expectation: .type)
		} else {
			if type.primitive != nil {
				return AnalyzedTypeExpr(
					wrapped: expr,
					symbol: .primitive(type.description),
					typeID: TypeID(type),
					environment: context
				)
			}

			return AnalyzedTypeExpr(
				wrapped: expr,
				symbol: context.symbolGenerator.struct(expr.identifier.lexeme, source: .internal),
				typeID: TypeID(type),
				environment: context
			)
		}
	}

	public func visit(_ expr: any FuncExpr, _ env: Environment) throws -> SourceFileAnalyzer.Value {
		var errors: [AnalysisError] = []
		let innerEnvironment = env.add(namespace: expr.autoname)

		// Define our parameters in the environment so they're declared in the body. They're
		// just placeholders for now.
		var params = try visit(expr.params, env) as! AnalyzedParamsExpr
		for param in params.paramsAnalyzed {
			innerEnvironment.define(parameter: param.name, as: param)
		}

		let symbol = if let scope = env.getLexicalScope() {
			env.symbolGenerator.method(scope.scope.name ?? scope.expr.description, expr.autoname, parameters: params.paramsAnalyzed.map(\.name), source: .internal)
		} else {
			env.symbolGenerator.function(expr.autoname, parameters: params.paramsAnalyzed.map(\.name), source: .internal)
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
					environment: env
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

		let bodyAnalyzed = try visit(expr.body, innerEnvironment) as! AnalyzedBlockStmt

		var declaredType: TypeID?
		if let typeDecl = expr.typeDecl {
			let type = env.type(named: typeDecl.identifier.lexeme)
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
			env.define(local: name.lexeme, as: funcExpr, isMutable: false)
		}

		return funcExpr
	}

	public func visit(_ expr: any InitDecl, _ context: Environment) throws -> any AnalyzedSyntax {
		let paramsAnalyzed = try expr.parameters.accept(self, context) as! AnalyzedParamsExpr

		let innerEnvironment = context.add(namespace: "init")
		for param in paramsAnalyzed.paramsAnalyzed {
			innerEnvironment.define(parameter: param.name, as: param)
		}

		let bodyAnalyzed = try expr.body.accept(self, innerEnvironment)

		guard let lexicalScope = innerEnvironment.getLexicalScope() else {
			return error(at: expr, "Could not determine lexical scope for init", environment: context, expectation: .none)
		}

		return AnalyzedInitDecl(
			wrapped: expr,
			symbol: context.symbolGenerator.method(lexicalScope.scope.name!, "init", parameters: paramsAnalyzed.paramsAnalyzed.map(\.name), source: .internal),
			typeID: TypeID(.struct(lexicalScope.scope.name!)),
			environment: innerEnvironment,
			parametersAnalyzed: paramsAnalyzed,
			bodyAnalyzed: bodyAnalyzed as! AnalyzedDeclBlock
		)
	}

	public func visit(_ expr: any ReturnStmt, _ env: Environment) throws -> SourceFileAnalyzer.Value {
		let valueAnalyzed = try expr.value?.accept(self, env)
		return AnalyzedReturnStmt(
			typeID: TypeID(valueAnalyzed?.typeAnalyzed ?? .void),
			environment: env,
			expr: expr,
			valueAnalyzed: valueAnalyzed as? any AnalyzedExpr
		)
	}

	public func visit(_ expr: any ParamsExpr, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		try AnalyzedParamsExpr(
			typeID: TypeID(.void),
			expr: expr,
			paramsAnalyzed: expr.params.enumerated().map { _, param in
				var type = TypeID()

				if let paramType = param.type {
					let analyzedTypeExpr = try visit(paramType, context)
					type = analyzedTypeExpr.typeID
				}

				return AnalyzedParam(
					type: type,
					expr: param,
					environment: context
				)
			},
			environment: context
		)
	}

	public func visit(_ expr: any WhileStmt, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		// TODO: Validate condition is bool
		let condition = try expr.condition.accept(self, context) as! any AnalyzedExpr
		let body = try visit(expr.body, context.withExitBehavior(.pop)) as! AnalyzedBlockStmt

		return AnalyzedWhileStmt(
			typeID: body.typeID,
			wrapped: expr,
			conditionAnalyzed: condition,
			bodyAnalyzed: body,
			environment: context
		)
	}

	public func visit(_ stmt: any BlockStmt, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		var bodyAnalyzed: [any AnalyzedSyntax] = []

		for bodyExpr in stmt.stmts {
			try bodyAnalyzed.append(bodyExpr.accept(self, context))
		}

		return AnalyzedBlockStmt(
			stmt: stmt,
			typeID: TypeID(bodyAnalyzed.last?.typeAnalyzed ?? .none),
			stmtsAnalyzed: bodyAnalyzed,
			environment: context
		)
	}

	public func visit(_ expr: any Param, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		AnalyzedParam(
			type: TypeID(),
			expr: expr,
			environment: context
		)
	}

	public func visit(_ expr: any GenericParams, _ environment: Environment) throws -> any AnalyzedSyntax {
		AnalyzedGenericParams(
			wrapped: expr,
			environment: environment,
			typeID: TypeID(),
			paramsAnalyzed: expr.params.map {
				AnalyzedGenericParam(wrapped: $0)
			}
		)
	}

	public func visit(_ expr: any StructDecl, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		try StructDeclAnalyzer(decl: expr, visitor: self, context: context).analyze()
	}

	public func visit(_ expr: any DeclBlock, _ context: Environment) throws
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
			decl: expr,
			declsAnalyzed: declsAnalyzed as! [any AnalyzedDecl],
			environment: context
		)
	}

	public func visit(_ expr: any VarDecl, _ context: Environment) throws -> SourceFileAnalyzer.Value {
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

		let type = TypeID(context.type(named: expr.typeExpr?.identifier.lexeme))
		var valueType = type
		let value = try expr.value?.accept(self, context) as? any AnalyzedExpr
		if let value, valueType.current == .placeholder {
			valueType = value.typeID
		}

		if case .error = type.current, context.shouldReportErrors {
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
			expr: expr,
			analysisErrors: errors,
			valueAnalyzed: value,
			environment: context
		)

		if let value {
			context.define(local: expr.name, as: value, definition: decl, isMutable: true, isGlobal: isGlobal)
		}

		return decl
	}

	public func visit(_ expr: any LetDecl, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		var errors: [AnalysisError] = []
		let type = TypeID(context.type(named: expr.typeExpr?.identifier.lexeme))

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
			expr: expr,
			analysisErrors: errors,
			valueAnalyzed: value,
			environment: context
		)

		if let value {
			context.define(local: expr.name, as: value, definition: decl, isMutable: false, isGlobal: isGlobal)
		}

		return decl
	}

	public func visit(_ expr: any IfStmt, _ context: Environment) throws -> any AnalyzedSyntax {
		try AnalyzedIfStmt(
			wrapped: expr,
			typeID: TypeID(.void),
			environment: context,
			conditionAnalyzed: expr.condition.accept(self, context) as! AnalyzedExpr,
			consequenceAnalyzed: expr.consequence.accept(self, context) as! AnalyzedExpr,
			alternativeAnalyzed: expr.alternative?.accept(self, context) as? AnalyzedExpr
		)
	}

	public func visit(_ expr: any StructExpr, _ context: Environment) throws -> any AnalyzedSyntax {
		AnalyzedErrorSyntax(typeID: TypeID(.error("TODO")), expr: ParseErrorSyntax(location: expr.location, message: "TODO", expectation: .none), environment: context)
	}

	public func visit(_ expr: any ArrayLiteralExpr, _ context: Environment) throws -> any AnalyzedSyntax {
		let elements = try expr.exprs.map { try $0.accept(self, context) }
		let elementType = elements.map(\.typeID).first ?? TypeID(.placeholder)
		let instanceType = InstanceValueType(ofType: .struct("Array"), boundGenericTypes: ["Element": elementType])

		var errors: [AnalysisError] = []
		if elements.count > 255 {
			errors.append(.init(kind: .expressionCount("Array literals can only have 255 elements"), location: expr.location))
		}

		context.importBinding(
			as: .struct("Standard", "Array"),
			from: "Standard",
			binding: .init(
				name: "Array",
				expr: expr,
				type: TypeID(.instance(.struct("Array"))),
				externalModule: context.importedModules.first(where: { $0.name == "Standard" })!
			)
		)

		return AnalyzedArrayLiteralExpr(
			environment: context,
			exprsAnalyzed: elements as! [any AnalyzedExpr],
			wrapped: expr,
			typeID: TypeID(.instance(instanceType)),
			analysisErrors: errors
		)
	}

	public func visit(_ expr: any SubscriptExpr, _ context: Environment) throws -> any AnalyzedSyntax {
		let receiver = try expr.receiver.accept(self, context) as! any AnalyzedExpr
		let args = try expr.args.map { try $0.accept(self, context) } as! [AnalyzedArgument]

		var result = AnalyzedSubscriptExpr(
			receiverAnalyzed: receiver,
			argsAnalyzed: args,
			wrapped: expr,
			typeID: TypeID(.placeholder),
			environment: context,
			analysisErrors: []
		)

		guard case let .instance(instance) = receiver.typeAnalyzed,
		      case let .struct(structName) = instance.ofType,
		      let structType = context.lookupStruct(named: structName),
		      let getMethod = structType.methods["get"]
		else {
			result.analysisErrors = [
				AnalysisError(kind: .noMemberFound(receiver: receiver, property: "get"), location: expr.location),
			]

			return result
		}

		result.typeID = getMethod.returnTypeID.resolve(with: instance)

		return result
	}
	public func visit(_ expr: any DictionaryLiteralExpr, _ context: Environment) throws -> any AnalyzedSyntax {
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

		context.importBinding(
			as: .struct("Standard", "Array"),
			from: "Standard",
			binding: .init(
				name: "Array",
				expr: expr,
				type: TypeID(.instance(.struct("Array"))),
				externalModule: context.importedModules.first(where: { $0.name == "Standard" })!
			)
		)

		context.importBinding(
			as: .struct("Standard", "Dictionary"),
			from: "Standard",
			binding: .init(
				name: "Dictionary",
				expr: expr,
				type: TypeID(.instance(.struct("Dictionary"))),
				externalModule: context.importedModules.first(where: { $0.name == "Standard" })!
			)
		)
		

		return AnalyzedDictionaryLiteralExpr(
			elementsAnalyzed: elementsAnalyzed,
			wrapped: expr,
			typeID: TypeID(.instance(instance)),
			environment: context
		)
	}

	public func visit(_ expr: any DictionaryElementExpr, _ context: Environment) throws -> any AnalyzedSyntax {
		let key = try expr.key.accept(self, context) as! any AnalyzedExpr
		let value = try expr.value.accept(self, context) as! any AnalyzedExpr
		return AnalyzedDictionaryElementExpr(
			keyAnalyzed: key,
			valueAnalyzed: value,
			wrapped: expr,
			typeID: TypeID(),
			environment: context
		)
	}

	// GENERATOR_INSERTION

	
}
