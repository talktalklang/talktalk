//
//  Analyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//
import TalkTalkSyntax

public struct Analyzer: Visitor {
	public typealias Context = Environment
	public typealias Value = any AnalyzedSyntax

	var errors: [String] = []

	public init() {}

	public static func diagnostics(text: String) throws -> [ErrorSyntax] {
		let parsed = Parser.parse(text)
		let analyzed = try Analyzer.analyze(parsed)

		func collect(expr: any AnalyzedSyntax) -> [ErrorSyntax] {
			var result: [ErrorSyntax] = []

			if let expr = expr as? ErrorSyntax {
				result.append(expr)
			}

			for child in expr.analyzedChildren {
				result.append(contentsOf: collect(expr: child))
			}

			return result
		}

		return collect(expr: analyzed)
	}

	public static func analyzedExprs(_ exprs: [any Expr]) throws -> [any AnalyzedSyntax] {
		let env = Environment()
		let analyzer = Analyzer()

		return try exprs.map { try $0.accept(analyzer, env) }
	}

	public static func analyze(_ exprs: [any Expr]) throws -> Analyzer.Value {
		let env = Environment()
		let analyzer = Analyzer()
		let location = exprs.first?.location ?? [.synthetic(.eof)]
		let name: Token = .synthetic(.identifier, lexeme: "main")

		let mainExpr = FuncExprSyntax(
			funcToken: .synthetic(.func),
			params: ParamsExprSyntax(params: [], location: location),
			body: BlockExprSyntax(exprs: exprs, location: location),
			i: 0,
			name: name,
			location: location
		)
		return try analyzer.visit(mainExpr, env)
	}

	public func visit(_ expr: any ImportStmt, _ context: Environment) -> Analyzer.Value {
		AnalyzedImportStmt(environment: context, type: .none, stmt: expr)
	}

	public func visit(_ expr: any IdentifierExpr, _ context: Environment) throws -> Analyzer.Value {
		AnalyzedIdentifierExpr(type: .placeholder(0), expr: expr, environment: context)
	}

	public func visit(_ expr: any UnaryExpr, _ context: Environment) throws -> Analyzer.Value {
		let exprAnalyzed = try expr.expr.accept(self, context)

		switch expr.op {
		case .bang:

			return AnalyzedUnaryExpr(
				type: .bool,
				exprAnalyzed: exprAnalyzed as! any AnalyzedExpr,
				environment: context,
				wrapped: expr
			)
		case .minus:
			return AnalyzedUnaryExpr(
				type: .int,
				exprAnalyzed: exprAnalyzed as! any AnalyzedExpr,
				environment: context,
				wrapped: expr
			)
		default:
			fatalError("unreachable")
		}
	}

	public func visit(_ expr: any CallExpr, _ context: Environment) throws -> Analyzer.Value {
		let callee = try expr.callee.accept(self, context)

		let args = try expr.args.map {
			try AnalyzedArgument(
				label: $0.label,
				expr: $0.value.accept(self, context) as! any AnalyzedExpr
			)
		}

		let type: ValueType

		switch callee.type {
		case let .function(_, t, _, _):
			type = t
		case let .struct(t):
			type = .instance(.struct(t))
		default:
			return error(
				at: callee, "callee not callable: \(callee), has type: \(callee.type)",
				environment: context,
				expectation: .decl
			)
		}

		return AnalyzedCallExpr(
			type: type,
			expr: expr,
			calleeAnalyzed: callee as! any AnalyzedExpr
,
			argsAnalyzed: args,
			environment: context
		)
	}

	public func visit(_ expr: any MemberExpr, _ context: Environment) throws -> Analyzer.Value {
		let receiver = try expr.receiver.accept(self, context)
		let propertyName = expr.property

		var property: Property? = nil
		switch receiver.type {
		case let .instance(.struct(instance)):
			property = instance.properties[propertyName] ?? instance.methods[propertyName]
		default:
			return error(
				at: expr, "Cannot access property \(propertyName) on \(receiver)",
				environment: context,
				expectation: .member
			)
		}

		guard let property else {
			return error(
				at: expr,
				"No property '\(propertyName)' found for \(receiver)",
				environment: context,
				expectation: .member
			)
		}

		return AnalyzedMemberExpr(
			type: property.type,
			expr: expr,
			environment: context,
			receiverAnalyzed: receiver as! any AnalyzedExpr

		)
	}

	public func visit(_ expr: any DefExpr, _ context: Environment) throws -> Analyzer.Value {
		let value = try expr.value.accept(self, context) as! any AnalyzedExpr


		context.define(local: expr.name.lexeme, as: value)

		return AnalyzedDefExpr(type: value.type, expr: expr, valueAnalyzed: value, environment: context)
	}

	public func visit(_ expr: any ErrorSyntax, _ context: Environment) throws -> Analyzer.Value {
		AnalyzedErrorSyntax(type: .error(expr.message), expr: expr, environment: context)
	}

	public func visit(_ expr: any LiteralExpr, _ context: Environment) throws -> Analyzer.Value {
		switch expr.value {
		case .int:
			AnalyzedLiteralExpr(type: .int, expr: expr, environment: context)
		case .bool:
			AnalyzedLiteralExpr(type: .bool, expr: expr, environment: context)
		case .none:
			AnalyzedLiteralExpr(type: .none, expr: expr, environment: context)
		case .string(_):
			AnalyzedLiteralExpr(type: .string, expr: expr, environment: context)
		}
	}

	public func visit(_ expr: any VarExpr, _ context: Environment) throws -> Analyzer.Value {
		if let binding = context.lookup(expr.name) {
			return AnalyzedVarExpr(
				type: binding.type,
				expr: expr,
				environment: context
			)
		}

		return error(
			at: expr, "undefined variable: \(expr.name) ln: \(expr.location.start.line) col: \(expr.location.start.column)",
			environment: context,
			expectation: .variable
		)
	}

	public func visit(_ expr: any BinaryExpr, _ env: Environment) throws -> Analyzer.Value {
		let lhs = try expr.lhs.accept(self, env) as! any AnalyzedExpr
		let rhs = try expr.rhs.accept(self, env) as! any AnalyzedExpr


		infer(lhs, rhs, as: .int, in: env)

		return AnalyzedBinaryExpr(type: .int, expr: expr, lhsAnalyzed: lhs, rhsAnalyzed: rhs, environment: env)
	}

	public func visit(_ expr: any IfExpr, _ context: Environment) throws -> Analyzer.Value {
		// TODO: Error if the branches don't match or condition isn't a bool
		try AnalyzedIfExpr(
			type: expr.consequence.accept(self, context).type,
			expr: expr,
			conditionAnalyzed: expr.condition.accept(self, context) as! any AnalyzedExpr,
			consequenceAnalyzed: visit(expr.consequence, context) as! AnalyzedBlockExpr,
			alternativeAnalyzed: visit(expr.alternative, context) as! AnalyzedBlockExpr,
			environment: context
		)
	}

	public func visit(_ expr: any FuncExpr, _ env: Environment) throws -> Analyzer.Value {
		let innerEnvironment = env.add()

		// Define our parameters in the environment so they're declared in the body. They're
		// just placeholders for now.
		var params = try visit(expr.params, env) as! AnalyzedParamsExpr
		for param in params.paramsAnalyzed {
			innerEnvironment.define(parameter: param.name, as: param)
		}

		if let name = expr.name {
			// If it's a named function, define a stub inside the function to allow for recursion
			let stub = AnalyzedFuncExpr(
				type: .function(name.lexeme, .placeholder(0), params, []),
				expr: expr,
				analyzedParams: params,
				bodyAnalyzed: .init(type: .placeholder(0), expr: expr.body, exprsAnalyzed: [], environment: env),
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

		let funcExpr = AnalyzedFuncExpr(
			type: .function(expr.name?.lexeme ?? expr.autoname, bodyAnalyzed.type, params, innerEnvironment.captures),
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

	public func visit(_ expr: any ReturnExpr, _ env: Environment) throws -> Analyzer.Value {
		let valueAnalyzed = try expr.value?.accept(self, env)
		return AnalyzedReturnExpr(
			type: valueAnalyzed?.type ?? .void,
			environment: env,
			expr: expr,
			valueAnalyzed: valueAnalyzed as? any AnalyzedExpr
		)
	}

	public func visit(_ expr: any ParamsExpr, _ context: Environment) throws -> Analyzer.Value {
		AnalyzedParamsExpr(
			type: .void,
			expr: expr,
			paramsAnalyzed: expr.params.enumerated().map { i, param in
				AnalyzedParam(type: .placeholder(i), expr: param, environment: context)
			},
			environment: context
		)
	}

	public func visit(_ expr: any WhileExpr, _ context: Environment) throws -> Analyzer.Value {
		// TODO: Validate condition is bool
		let condition = try expr.condition.accept(self, context) as! any AnalyzedExpr
		let body = try visit(expr.body, context) as! AnalyzedBlockExpr

		return AnalyzedWhileExpr(
			type: body.type,
			expr: expr,
			conditionAnalyzed: condition,
			bodyAnalyzed: body,
			environment: context
		)
	}

	public func visit(_ expr: any BlockExpr, _ context: Environment) throws -> Analyzer.Value {
		var bodyAnalyzed: [any AnalyzedExpr] = []
		for bodyExpr in expr.exprs {
			try bodyAnalyzed.append(bodyExpr.accept(self, context) as! any AnalyzedExpr)
		}

		return AnalyzedBlockExpr(type: bodyAnalyzed.last?.type ?? .none, expr: expr, exprsAnalyzed: bodyAnalyzed, environment: context)
	}

	public func visit(_ expr: any Param, _ context: Environment) throws -> Analyzer.Value {
		AnalyzedParam(type: .placeholder(1), expr: expr, environment: context)
	}

	public func visit(_ expr: any StructExpr, _ context: Environment) throws -> Analyzer.Value {
		let structType = StructType(name: expr.name, properties: [:], methods: [:])
		let bodyContext = context.addLexicalScope(scope: structType, type: .struct(structType), expr: expr)

		bodyContext.define(
			local: "self",
			as: AnalyzedVarExpr(
				type: .instance(.struct(structType)),
				expr: VarExprSyntax(
					token: .synthetic(.self),
					location: [.synthetic(.self)]
				),
				environment: context
			)
		)

		// Do a first pass over the body decls so we have a basic idea of what's available in
		// this struct.
		for decl in expr.body.decls {
			switch decl {
			case let decl as VarDecl:
				structType.add(property: Property(
					name: decl.name,
					type: context.type(named: decl.typeDecl),
					expr: decl,
					isMutable: true
				))
			case let decl as LetDecl:
				structType.add(property: Property(
					name: decl.name,
					type: context.type(named: decl.typeDecl),
					expr: decl,
					isMutable: false
				))
			case let decl as FuncExpr:
				structType.add(method: Property(
					name: decl.name!.lexeme,
					type: .function(decl.name!.lexeme, .placeholder(2), [], []),
					expr: decl,
					isMutable: false
				))
			default:
				fatalError()
			}
		}

		// Do a second pass to try to fill in method returns
		let bodyAnalyzed = try visit(expr.body, bodyContext)

		let type: ValueType = .struct(
			structType
		)

		let lexicalScope = bodyContext.lexicalScope!

		let analyzed = AnalyzedStructExpr(
			type: type,
			expr: expr,
			bodyAnalyzed: bodyAnalyzed as! AnalyzedDeclBlock,
			structType: structType,
			lexicalScope: lexicalScope,
			environment: context
		)

		if let name = expr.name {
			context.define(local: name, as: analyzed)
		}

		bodyContext.lexicalScope = lexicalScope

		return analyzed
	}

	public func visit(_ expr: any DeclBlockExpr, _ context: Environment) throws -> Analyzer.Value {
		var declsAnalyzed: [any AnalyzedExpr] = []

		// Do a first pass over the body decls so we have a basic idea of what's available in
		// this struct.
		for decl in expr.decls {
			let declAnalyzed = try decl.accept(self, context)

			declsAnalyzed.append(declAnalyzed as! any AnalyzedExpr)

			// If we have an updated type for a method, update the struct to know about it.
			if let funcExpr = declAnalyzed as? AnalyzedFuncExpr,
				 let lexicalScope = context.lexicalScope {
				lexicalScope.scope.add(method: Property(
					name: funcExpr.name!.lexeme,
					type: funcExpr.type,
					expr: funcExpr,
					isMutable: false
				))
			}
		}

		return AnalyzedDeclBlock(type: .void, decl: expr, declsAnalyzed: declsAnalyzed as! [any AnalyzedDecl], environment: context)
	}

	public func visit(_ expr: any VarDecl, _ context: Environment) throws -> Analyzer.Value {
		AnalyzedVarDecl(type: context.type(named: expr.typeDecl), expr: expr, environment: context)
	}

	private func infer(_ exprs: (any AnalyzedExpr)..., as type: ValueType, in env: Environment) {
		if case .placeholder = type { return }

		for expr in exprs {
			if var expr = expr as? AnalyzedVarExpr {
				expr.type = type
				env.update(local: expr.name, as: type)
				if let capture = env.captures.first(where: { $0.name == expr.name }) {
					capture.binding.type = type
				}
			}
		}
	}

	public func error(at expr: any Syntax, _ message: String, environment: Analyzer.Environment, expectation: ParseExpectation) -> AnalyzedErrorSyntax {
		AnalyzedErrorSyntax(
			type: .error(message),
			expr: SyntaxError(location: expr.location, message: message, expectation: expectation),
			environment: environment
		)
	}
}
