//
//  Analyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//
import Foundation
import TalkTalkSyntax

// Analyze the AST, trying to figure out types and also checking for errors
public struct SourceFileAnalyzer: Visitor {
	public typealias Context = Environment
	public typealias Value = any AnalyzedSyntax

	var errors: [String] = []

	public init() {}

	public static func diagnostics(
		text: String,
		environment: Environment
	) throws -> Set<AnalysisError> {
		let parsed = try Parser.parse(text, allowErrors: true)
		let analyzed = try SourceFileAnalyzer.analyze(parsed, in: environment)

		func collect(syntaxes: [any AnalyzedSyntax]) -> Set<AnalysisError> {
			var result: Set<AnalysisError> = []

			for syntax in syntaxes {
				if let err = syntax as? ErrorSyntax {
					// TODO: We wanna move away from this towards nodes just having their own errors
					result.insert(
						AnalysisError(kind: .unknownError(err.message), location: syntax.location)
					)
				}

				for error in syntax.analysisErrors {
					result.insert(error)
				}

				for error in collect(syntaxes: syntax.analyzedChildren) {
					result.insert(error)
				}
			}

			return result
		}

		return collect(syntaxes: analyzed)
	}

	public static func analyze(_ exprs: [any Syntax], in environment: Environment) throws
		-> [Value]
	{
		let analyzer = SourceFileAnalyzer()
		var analyzed = try exprs.map { try $0.accept(analyzer, environment) }

		// If it's just a single statement, just make it a return
		if analyzed.count == 1, let exprStmt = analyzed[0] as? AnalyzedExprStmt {
			analyzed[0] = AnalyzedReturnExpr(
				typeID: exprStmt.typeID,
				environment: environment,
				expr: ReturnExprSyntax(
					returnToken: .synthetic(.return),
					location: [exprStmt.location.start]
				),
				valueAnalyzed: exprStmt.exprAnalyzed
			)
		}

		return analyzed
	}

	public func visit(_ expr: any ExprStmt, _ context: Environment) throws -> any AnalyzedSyntax {
		try AnalyzedExprStmt(
			wrapped: expr,
			exprAnalyzed: expr.expr.accept(self, context) as! any AnalyzedExpr,
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

	public func visit(_ expr: any CallExpr, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		var callee = try expr.callee.accept(self, context)

		// Unwrap expr stmt
		if let exprStmt = callee as? AnalyzedExprStmt {
			callee = exprStmt.exprAnalyzed
		}

		var errors: [AnalysisError] = []

		let args = try expr.args.map {
			try AnalyzedArgument(
				label: $0.label,
				expr: $0.value.accept(self, context) as! any AnalyzedExpr
			)
		}

		let type: TypeID
		let arity: Int

		switch callee.typeAnalyzed {
		case let .function(_, returning, params, _):
			if params.count == args.count {
				// Try to infer param types
				for (i, param) in params.enumerated() {
					if case .placeholder = param.typeID.type() {
						param.typeID.update(args[i].expr.typeAnalyzed)
					}
				}
			}

			type = returning
			arity = params.count
		case let .struct(t):
			guard let structType = context.lookupStruct(named: t) else {
				return error(
					at: callee, "could not find struct named: \(t)",
					environment: context,
					expectation: .decl
				)
			}

			var instanceType = InstanceValueType.struct(t)

			if let callee = callee as? AnalyzedTypeExpr,
			   let params = callee.genericParams, !params.isEmpty
			{
				// Fill in type parameters if they're explicitly annotated. If they're not we'll have to try to infer them.
				if params.count == structType.typeParameters.count {
					for (i, param) in structType.typeParameters.enumerated() {
						let typeName = params.params[i].name
						let type = context.type(named: typeName)
						instanceType.boundGenericTypes[param.name] = type
					}
				} else {
					errors.append(
						context.report(.typeParameterError(
							expected: structType.typeParameters.count,
							received: params.count
						), at: expr.location)
					)
				}
			} else if !structType.typeParameters.isEmpty, let initFn = structType.methods["init"] {
				// Try to infer type parameters from init
				for arg in args {
					// See if we have a label for the arg (could maybe rely on positions here??)
					guard let label = arg.label else { continue }
					// Find the param definition from the init
					guard let param = initFn.params[label] else { continue }

					if case let .instance(paramInstanceType) = param.type(),
					   case let .generic(.struct(structType.name!), typeName) = paramInstanceType.ofType
					{
						instanceType.boundGenericTypes[typeName] = arg.expr.typeAnalyzed
					}
				}
			}

			// TODO: also type check args better?

			type = TypeID(.instance(instanceType))
			arity = structType.methods["init"]!.params.count
		default:
			return error(
				at: callee, "callee not callable: \(callee.typeID.current.description), has type: \(callee.typeAnalyzed)",
				environment: context,
				expectation: .decl
			)
		}

		if arity != args.count {
			errors.append(
				context.report(.argumentError(expected: arity, received: args.count), at: expr.location)
			)
		}

		return AnalyzedCallExpr(
			typeID: type,
			expr: expr,
			calleeAnalyzed: callee as! any AnalyzedExpr,
			argsAnalyzed: args,
			analysisErrors: errors,
			environment: context
		)
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
				at: expr, "Cannot access property \(propertyName) on \(receiver)",
				environment: context,
				expectation: .member
			)
		}

		guard let member else {
			return error(
				at: expr,
				"No property '\(propertyName)' found for \(receiver)",
				environment: context,
				expectation: .member
			)
		}

		return AnalyzedMemberExpr(
			typeID: member.typeID,
			expr: expr,
			environment: context,
			receiverAnalyzed: receiver as! any AnalyzedExpr,
			memberAnalyzed: member,
			analysisErrors: []
		)
	}

	public func visit(_ expr: any DefExpr, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		let value = try expr.value.accept(self, context) as! any AnalyzedExpr

		switch expr.receiver {
		case let receiver as any VarExpr:
			context.define(local: receiver.name, as: value)
		default: ()
		}

		let receiver = try expr.receiver.accept(self, context) as! any AnalyzedExpr
		return AnalyzedDefExpr(
			typeID: TypeID(value.typeAnalyzed),
			expr: expr,
			receiverAnalyzed: receiver,
			valueAnalyzed: value,
			environment: context
		)
	}

	public func visit(_ expr: any ErrorSyntax, _ context: Environment) throws
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
			TypeID(.string)
		}

		return AnalyzedLiteralExpr(
			typeID: typeID,
			expr: expr,
			environment: context
		)
	}

	public func visit(_ expr: any VarExpr, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		if let binding = context.lookup(expr.name) {
			return AnalyzedVarExpr(
				typeID: binding.type,
				expr: expr,
				environment: context
			)
		}

		return error(
			at: expr,
			"undefined variable: \(expr.name) ln: \(expr.location.start.line) col: \(expr.location.start.column)",
			environment: context,
			expectation: .variable
		)
	}

	public func visit(_ expr: any BinaryExpr, _ env: Environment) throws -> SourceFileAnalyzer.Value {
		let lhs = try expr.lhs.accept(self, env) as! any AnalyzedExpr
		let rhs = try expr.rhs.accept(self, env) as! any AnalyzedExpr

		infer(lhs, rhs, as: .int, in: env)

		return AnalyzedBinaryExpr(
			typeID: TypeID(.int),
			expr: expr,
			lhsAnalyzed: lhs,
			rhsAnalyzed: rhs,
			environment: env
		)
	}

	public func visit(_ expr: any IfExpr, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		// TODO: Error if the branches don't match or condition isn't a bool
		try AnalyzedIfExpr(
			typeID: expr.consequence.accept(self, context).typeID,
			expr: expr,
			conditionAnalyzed: expr.condition.accept(self, context) as! any AnalyzedExpr,
			consequenceAnalyzed: visit(expr.consequence, context) as! AnalyzedBlockExpr,
			alternativeAnalyzed: visit(expr.alternative, context) as! AnalyzedBlockExpr,
			environment: context
		)
	}

	public func visit(_ expr: any TypeExpr, _ context: Environment) throws -> any AnalyzedSyntax {
		let type = context.type(named: expr.identifier.lexeme)

		if case let .error(err) = type {
			return error(at: expr, err, environment: context, expectation: .type)
		} else {
			return AnalyzedTypeExpr(
				wrapped: expr,
				typeID: TypeID(type),
				environment: context
			)
		}
	}

	public func visit(_ expr: any FuncExpr, _ env: Environment) throws -> SourceFileAnalyzer.Value {
		let innerEnvironment = env.add()

		// Define our parameters in the environment so they're declared in the body. They're
		// just placeholders for now.
		var params = try visit(expr.params, env) as! AnalyzedParamsExpr
		for param in params.paramsAnalyzed {
			innerEnvironment.define(parameter: param.name, as: param)
		}

		if let name = expr.name {
			// If it's a named function, define a stub inside the function to allow for recursion
			let stubType = ValueType.function(
				name.lexeme,
				TypeID(.placeholder(0)),
				params.paramsAnalyzed.map {
					.init(name: $0.name, typeID: $0.typeID)
				},
				[]
			)
			let stub = AnalyzedFuncExpr(
				type: TypeID(stubType),
				expr: expr,
				analyzedParams: params,
				bodyAnalyzed: .init(
					expr: expr.body,
					typeID: TypeID(),
					exprsAnalyzed: [],
					environment: env
				),
				returnsAnalyzed: nil,
				environment: innerEnvironment
			)
			innerEnvironment.define(local: name.lexeme, as: stub)
		}

		// Visit the body with the innerEnvironment, finding captures as we go.
		let bodyAnalyzed = try visit(expr.body, innerEnvironment) as! AnalyzedBlockExpr

		// See if we can infer any types for our params from the environment after the body
		// has been visited.
		params.infer(from: innerEnvironment)

		let analyzed = ValueType.function(
			expr.name?.lexeme ?? expr.autoname,
			bodyAnalyzed.typeID,
			params.paramsAnalyzed.map { .init(name: $0.name, typeID: $0.typeID) },
			innerEnvironment.captures.map(\.name)
		)

		let funcExpr = AnalyzedFuncExpr(
			type: TypeID(analyzed),
			expr: expr,
			analyzedParams: params,
			bodyAnalyzed: bodyAnalyzed,
			returnsAnalyzed: bodyAnalyzed.exprsAnalyzed.last,
			environment: innerEnvironment
		)

		if let name = expr.name {
			innerEnvironment.define(local: name.lexeme, as: funcExpr)
			env.define(local: name.lexeme, as: funcExpr)
		}

		return funcExpr
	}

	public func visit(_ expr: any InitDecl, _ context: Environment) throws -> any AnalyzedSyntax {
		let paramsAnalyzed = try expr.parameters.accept(self, context)
		let bodyAnalyzed = try expr.body.accept(self, context)

		return AnalyzedInitDecl(
			wrapped: expr,
			typeID: TypeID(.struct(context.lexicalScope!.scope.name!)),
			environment: context,
			parametersAnalyzed: paramsAnalyzed as! AnalyzedParamsExpr,
			bodyAnalyzed: bodyAnalyzed as! AnalyzedBlockExpr
		)
	}

	public func visit(_ expr: any ReturnExpr, _ env: Environment) throws -> SourceFileAnalyzer.Value {
		let valueAnalyzed = try expr.value?.accept(self, env)
		return AnalyzedReturnExpr(
			typeID: TypeID(valueAnalyzed?.typeAnalyzed ?? .void),
			environment: env,
			expr: expr,
			valueAnalyzed: valueAnalyzed as? any AnalyzedExpr
		)
	}

	public func visit(_ expr: any ParamsExpr, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		AnalyzedParamsExpr(
			typeID: TypeID(.void),
			expr: expr,
			paramsAnalyzed: expr.params.enumerated().map { _, param in
				AnalyzedParam(
					type: TypeID(),
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
		let body = try visit(expr.body, context.withNoAutoReturn()) as! AnalyzedBlockExpr

		return AnalyzedWhileStmt(
			typeID: body.typeID,
			wrapped: expr,
			conditionAnalyzed: condition,
			bodyAnalyzed: body,
			environment: context
		)
	}

	public func visit(_ expr: any BlockExpr, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		var bodyAnalyzed: [any AnalyzedSyntax] = []

		for bodyExpr in expr.exprs {
			try bodyAnalyzed.append(bodyExpr.accept(self, context))
		}

		// Add an implicit return for single statement blocks
		if context.canAutoReturn, expr.exprs.count == 1, let exprStmt = bodyAnalyzed[0] as? AnalyzedExprStmt {
			bodyAnalyzed[0] = AnalyzedReturnExpr(
				typeID: exprStmt.typeID,
				environment: context,
				expr: ReturnExprSyntax(
					returnToken: .synthetic(.return),
					location: [exprStmt.location.start]
				),
				valueAnalyzed: exprStmt.exprAnalyzed
			)
		}

		return AnalyzedBlockExpr(
			expr: expr,
			typeID: TypeID(bodyAnalyzed.last?.typeAnalyzed ?? .none),
			exprsAnalyzed: bodyAnalyzed,
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

	public func visit(_ expr: any GenericParams, _ context: Environment) throws -> any AnalyzedSyntax {
		AnalyzedGenericParams(
			wrapped: expr,
			typeID: TypeID(),
			paramsAnalyzed: expr.params.map {
				AnalyzedGenericParam(wrapped: $0)
			}
		)
	}

	public func visit(_ expr: any StructDecl, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		var typeParameters: [TypeParameter] = []
		if let genericParams = expr.genericParams {
			for param in genericParams.params {
				typeParameters.append(.init(name: param.name, type: .placeholder(0)))
			}
		}

		let structType = StructType(
			name: expr.name,
			properties: [:],
			methods: [:],
			typeParameters: typeParameters
		)

		let bodyContext = context.addLexicalScope(
			scope: structType,
			type: .struct(expr.name),
			expr: expr
		)

		bodyContext.define(
			local: "self",
			as: AnalyzedVarExpr(
				typeID: TypeID(
					.instance(.struct(expr.name))
				),
				expr: VarExprSyntax(
					token: .synthetic(.self),
					location: [.synthetic(.self)]
				),
				environment: context
			)
		)

		context.define(struct: expr.name, as: structType)
		bodyContext.define(struct: expr.name, as: structType)

		// Do a first pass over the body decls so we have a basic idea of what's available in
		// this struct.
		for decl in expr.body.decls {
			switch decl {
			case let decl as VarDecl:
				var type = bodyContext.type(named: decl.typeDecl)

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
				var type = bodyContext.type(named: decl.typeDecl)

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
			case let decl as ExprStmt:
				if let decl = decl.expr as? FuncExpr {
					if let name = decl.name {
						structType.add(
							method: Method(
								slot: structType.methods.count,
								name: name.lexeme,
								params: decl
									.params
									.params
									.map(\.name)
									.reduce(into: [:]) { res, p in
										res[p] = TypeID(.placeholder(0))
									},
								typeID: TypeID(
									.function(
										name.lexeme,
										TypeID(.placeholder(2)),
										[],
										[]
									)
								),
								expr: decl,
								isMutable: false
							))
					}
				} else {
					FileHandle.standardError.write(Data(("unknown decl in struct: \(decl.debugDescription)" + "\n").utf8))
				}
			case let decl as InitDecl:
				structType.add(
					initializer: .init(
						slot: structType.methods.count,
						name: "init",
						params: decl
							.parameters
							.params
							.map(\.name)
							.reduce(into: [:]) { res, p
								in res[p] = TypeID(.placeholder(0))
							},
						typeID: TypeID(
							.function(
								"init",
								TypeID(.placeholder(2)),
								[],
								[]
							)
						),
						expr: decl,
						isMutable: false
					))
			case is ErrorSyntax:
				()
			default:
				FileHandle.standardError.write(Data(("unknown decl in struct: \(decl.debugDescription)" + "\n").utf8))
			}
		}

		// Do a second pass to try to fill in method returns
		let bodyAnalyzed = try visit(expr.body, bodyContext)

		let type: ValueType = .struct(
			structType.name ?? expr.description
		)

		// See if there's an initializer defined. If not, generate one.
		if structType.methods["init"] == nil {
			structType.add(
				initializer: .init(
					slot: structType.methods.count,
					name: "init",
					params: structType.properties.reduce(into: [:]) { res, prop in res[prop.key] = prop.value.typeID },
					typeID: TypeID(
						.function(
							"init",
							TypeID(.placeholder(2)),
							[],
							[]
						)
					),
					expr: expr,
					isMutable: false,
					isSynthetic: true
				))
		}

		let lexicalScope = bodyContext.lexicalScope!

		let analyzed = AnalyzedStructDecl(
			wrapped: expr,
			bodyAnalyzed: bodyAnalyzed as! AnalyzedDeclBlock,
			structType: structType,
			lexicalScope: lexicalScope,
			typeID: TypeID(type),
			environment: context
		)

		context.define(local: expr.name, as: analyzed)

		bodyContext.lexicalScope = lexicalScope

		return analyzed
	}

	public func visit(_ expr: any DeclBlockExpr, _ context: Environment) throws
		-> SourceFileAnalyzer.Value
	{
		var declsAnalyzed: [any AnalyzedExpr] = []

		// Do a first pass over the body decls so we have a basic idea of what's available in
		// this struct.
		for decl in expr.decls {
			guard var declAnalyzed = try decl.accept(self, context) as? any AnalyzedDecl else {
				continue
			}

			declsAnalyzed.append(declAnalyzed)

			if let exprStmt = declAnalyzed as? AnalyzedExprStmt,
			   let wrappedDecl = exprStmt.exprAnalyzed as? any AnalyzedDecl
			{
				declAnalyzed = wrappedDecl
			}

			// If we have an updated type for a method, update the struct to know about it.
			if let funcExpr = declAnalyzed as? AnalyzedFuncExpr,
			   let lexicalScope = context.lexicalScope,
			   let name = funcExpr.name?.lexeme,
			   let existing = lexicalScope.scope.methods[name]
			{
				lexicalScope.scope.add(
					method: Method(
						slot: existing.slot,
						name: funcExpr.name!.lexeme,
						params: funcExpr.params.params.map(\.name).reduce(into: [:]) { res, p in res[p] = TypeID(.placeholder(0)) },
						typeID: funcExpr.typeID,
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
		let type = context.type(named: expr.typeDecl)

		if case .error(_) = type {
			errors.append(
				.init(
					kind: .typeNotFound(expr.typeDecl ?? "<no type name>"),
					location: [expr.typeDeclToken ?? expr.location.start]
				)
			)
		}

		let value = try expr.value?.accept(self, context) as? any AnalyzedExpr
		if let value {
			context.define(local: expr.name, as: value)
		}

		return AnalyzedVarDecl(
			typeID: TypeID(type),
			expr: expr,
			analysisErrors: errors,
			valueAnalyzed: value,
			environment: context
		)
	}

	public func visit(_ expr: any LetDecl, _ context: Environment) throws -> SourceFileAnalyzer.Value {
		var errors: [AnalysisError] = []
		let type = context.type(named: expr.typeDecl)

		if case .error(_) = type {
			errors.append(.init(kind: .typeNotFound(expr.typeDecl ?? "<no type name>"), location: [expr.typeDeclToken ?? expr.location.start]))
		}

		let value = try expr.value?.accept(self, context) as? any AnalyzedExpr
		if let value {
			if !context.isModuleScope {
				context.define(local: expr.name, as: value)
			}
		}

		return AnalyzedLetDecl(
			typeID: TypeID(type),
			expr: expr,
			analysisErrors: errors,
			valueAnalyzed: value,
			environment: context
		)
	}

	public func visit(_ expr: any IfStmt, _ context: Environment) throws -> any AnalyzedSyntax {
		return try AnalyzedIfStmt(
			wrapped: expr,
			typeID: TypeID(.void),
			conditionAnalyzed: expr.condition.accept(self, context) as! AnalyzedExpr,
			consequenceAnalyzed: expr.consequence.accept(self, context.withNoAutoReturn()) as! AnalyzedExpr,
			alternativeAnalyzed: expr.alternative?.accept(self, context.withNoAutoReturn()) as? AnalyzedExpr
		)
	}


	public func visit(_ expr: any StructExpr, _ context: Environment) throws -> any AnalyzedSyntax {
		fatalError("TODO")
	}


	// GENERATOR_INSERTION

	private func infer(_ exprs: (any AnalyzedExpr)..., as type: ValueType, in env: Environment) {
		if case .placeholder = type { return }

		for var expr in exprs {
			if let exprStmt = expr as? AnalyzedExprStmt {
				// Unwrap expr stmt
				expr = exprStmt.exprAnalyzed
			}

			if let expr = expr as? AnalyzedVarExpr {
				expr.typeID.update(type)
				env.update(local: expr.name, as: type)
				if let capture = env.captures.first(where: { $0.name == expr.name }) {
					capture.binding.type.update(type)
				}
			}
		}
	}

	public func error(
		at expr: any Syntax, _ message: String, environment: Environment, expectation: ParseExpectation
	) -> AnalyzedErrorSyntax {
		AnalyzedErrorSyntax(
			typeID: TypeID(.error(message)),
			expr: SyntaxError(location: expr.location, message: message, expectation: expectation),
			environment: environment
		)
	}
}
