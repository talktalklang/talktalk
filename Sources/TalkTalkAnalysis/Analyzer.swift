//
//  Analyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//
import TalkTalkSyntax

public struct Analyzer: Visitor {
	public typealias Context = Environment
	public typealias Value = any AnalyzedExpr

	var errors: [String] = []

	public init() {}

	public static func analyze(_ exprs: [any Expr]) -> any AnalyzedExpr {
		let env = Environment()
		let analyzer = Analyzer()
		let location = exprs.first?.location ?? [.synthetic(.eof)]

		let mainExpr = FuncExprSyntax(
			params: ParamsExprSyntax(params: [], location: location),
			body: BlockExprSyntax(exprs: exprs, location: location),
			i: 0,
			name: "main",
			location: location
		)
		return analyzer.visit(mainExpr, env)
	}

	public func visit(_ expr: any CallExpr, _ context: Environment) -> any AnalyzedExpr {
		let callee = expr.callee.accept(self, context)

		let args = expr.args.map {
			AnalyzedArgument(label: $0.label, expr: $0.value.accept(self, context))
		}

		let type: ValueType

		switch callee.type {
		case let .function(_, t, _, _):
			type = t
		case let .struct(t):
			type = .instance(.struct(t))
		default:
			return error(at: callee, "callee not callable: \(callee), has type: \(callee.type)")
		}

		return AnalyzedCallExpr(
			type: type,
			expr: expr,
			calleeAnalyzed: callee,
			argsAnalyzed: args
		)
	}

	public func visit(_ expr: any MemberExpr, _ context: Environment) -> any AnalyzedExpr {
		let receiver = expr.receiver.accept(self, context)
		let propertyName = expr.property

		var property: Property? = nil
		switch receiver.type {
		case let .instance(.struct(instance)):
			property = instance.properties[propertyName] ?? instance.methods[propertyName]
		default:
			return error(at: expr, "Cannot access property \(propertyName) on \(receiver)")
		}

		guard let property else {
			return error(at: expr, "No property '\(propertyName)' found for \(receiver)")
		}

		return AnalyzedMemberExpr(
			type: property.type,
			expr: expr,
			receiverAnalyzed: receiver
		)
	}

	public func visit(_ expr: any DefExpr, _ context: Environment) -> any AnalyzedExpr {
		let value = expr.value.accept(self, context)

		context.define(local: expr.name.lexeme, as: value)

		return AnalyzedDefExpr(type: value.type, expr: expr, valueAnalyzed: value)
	}

	public func visit(_ expr: any ErrorSyntax, _: Environment) -> any AnalyzedExpr {
		AnalyzedErrorSyntax(type: .error(expr.message), expr: expr)
	}

	public func visit(_ expr: any LiteralExpr, _: Environment) -> any AnalyzedExpr {
		switch expr.value {
		case .int:
			AnalyzedLiteralExpr(type: .int, expr: expr)
		case .bool:
			AnalyzedLiteralExpr(type: .bool, expr: expr)
		case .none:
			AnalyzedLiteralExpr(type: .none, expr: expr)
		}
	}

	public func visit(_ expr: any VarExpr, _ context: Environment) -> any AnalyzedExpr {
		if let binding = context.lookup(expr.name) {
			return AnalyzedVarExpr(
				type: binding.type,
				expr: expr
			)
		}

		return error(at: expr, "undefined variable: \(expr.name)")
	}

	public func visit(_ expr: any BinaryExpr, _ env: Environment) -> any AnalyzedExpr {
		let lhs = expr.lhs.accept(self, env)
		let rhs = expr.rhs.accept(self, env)

		infer(lhs, rhs, as: .int, in: env)

		return AnalyzedBinaryExpr(type: .int, expr: expr, lhsAnalyzed: lhs, rhsAnalyzed: rhs)
	}

	public func visit(_ expr: any IfExpr, _ context: Environment) -> any AnalyzedExpr {
		// TODO: Error if the branches don't match or condition isn't a bool
		AnalyzedIfExpr(
			type: expr.consequence.accept(self, context).type,
			expr: expr,
			conditionAnalyzed: expr.condition.accept(self, context),
			consequenceAnalyzed: visit(expr.consequence, context) as! AnalyzedBlockExpr,
			alternativeAnalyzed: visit(expr.alternative, context) as! AnalyzedBlockExpr
		)
	}

	public func visit(_ expr: any FuncExpr, _ env: Environment) -> any AnalyzedExpr {
		let innerEnvironment = env.add()

		// Define our parameters in the environment so they're declared in the body. They're
		// just placeholders for now.
		var params = visit(expr.params, env) as! AnalyzedParamsExpr
		for param in params.paramsAnalyzed {
			innerEnvironment.define(local: param.name, as: param)
		}

		// Visit the body with the innerEnvironment, finding captures as we go.
		let bodyAnalyzed = visit(expr.body, innerEnvironment) as! AnalyzedBlockExpr

		// See if we can infer any types for our params from the environment after the body
		// has been visited.
		params.infer(from: innerEnvironment)

		let funcExpr = AnalyzedFuncExpr(
			type: .function(expr.name ?? expr.autoname, bodyAnalyzed.type, params, innerEnvironment.captures),
			expr: expr,
			analyzedParams: params,
			bodyAnalyzed: bodyAnalyzed,
			returnsAnalyzed: bodyAnalyzed.exprsAnalyzed.last,
			environment: innerEnvironment
		)

		if let name = expr.name {
			env.define(local: name, as: funcExpr)
		}

		return funcExpr
	}

	public func visit(_ expr: any ParamsExpr, _: Environment) -> any AnalyzedExpr {
		AnalyzedParamsExpr(
			type: .void,
			expr: expr,
			paramsAnalyzed: expr.params.enumerated().map { i, param in
				AnalyzedParam(type: .placeholder(i), expr: param)
			}
		)
	}

	public func visit(_ expr: any WhileExpr, _ context: Environment) -> any AnalyzedExpr {
		// TODO: Validate condition is bool
		let condition = expr.condition.accept(self, context)
		let body = visit(expr.body, context) as! AnalyzedBlockExpr

		return AnalyzedWhileExpr(type: body.type, expr: expr, conditionAnalyzed: condition, bodyAnalyzed: body)
	}

	public func visit(_ expr: any BlockExpr, _ context: Environment) -> any AnalyzedExpr {
		var bodyAnalyzed: [any AnalyzedExpr] = []
		for bodyExpr in expr.exprs {
			bodyAnalyzed.append(bodyExpr.accept(self, context))
		}

		return AnalyzedBlockExpr(type: bodyAnalyzed.last?.type ?? .none, expr: expr, exprsAnalyzed: bodyAnalyzed)
	}

	public func visit(_ expr: any Param, _: Environment) -> any AnalyzedExpr {
		AnalyzedParam(type: .placeholder(1), expr: expr)
	}

	public func visit(_ expr: any StructExpr, _ context: Environment) -> any AnalyzedExpr {
		let structType = StructType(name: expr.name, properties: [:], methods: [:])
		let bodyContext = context.addLexicalScope(scope: structType, type: .struct(structType), expr: expr)

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
					name: decl.name!,
					type: .function(decl.name!, .placeholder(2), [], []),
					expr: decl,
					isMutable: false
				))
			default:
				fatalError()
			}
		}

		// Do a second pass to try to fill in method returns
		let bodyAnalyzed = visit(expr.body, bodyContext)

		let type: ValueType = .struct(
			structType
		)

		let lexicalScope = bodyContext.lexicalScope!

		let analyzed = AnalyzedStructExpr(
			type: type,
			expr: expr,
			bodyAnalyzed: bodyAnalyzed as! AnalyzedDeclBlock,
			structType: structType,
			lexicalScope: lexicalScope
		)

		if let name = expr.name {
			context.define(local: name, as: analyzed)
		}

		bodyContext.lexicalScope = lexicalScope

		return analyzed
	}

	public func visit(_ expr: any DeclBlockExpr, _ context: Environment) -> any AnalyzedExpr {
		var declsAnalyzed: [any AnalyzedExpr] = []

		// Do a first pass over the body decls so we have a basic idea of what's available in
		// this struct.
		for decl in expr.decls {
			let declAnalyzed = decl.accept(self, context)

			declsAnalyzed.append(declAnalyzed)

			// If we have an updated type for a method, update the struct to know about it.
			if let funcExpr = declAnalyzed as? AnalyzedFuncExpr,
				 let lexicalScope = context.lexicalScope {
				lexicalScope.scope.add(method: Property(
					name: funcExpr.name!,
					type: funcExpr.type,
					expr: funcExpr,
					isMutable: false
				))
			}
		}

		return AnalyzedDeclBlock(type: .void, decl: expr, declsAnalyzed: declsAnalyzed as! [any AnalyzedDecl])
	}

	public func visit(_ expr: any VarDecl, _ context: Environment) -> any AnalyzedExpr {
		AnalyzedVarDecl(type: context.type(named: expr.typeDecl), expr: expr)
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

	public func error(at expr: any Expr, _ message: String) -> AnalyzedErrorSyntax {
		AnalyzedErrorSyntax(type: .error(message), expr: SyntaxError(location: expr.location, message: message))
	}
}
