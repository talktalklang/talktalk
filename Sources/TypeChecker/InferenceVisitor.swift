//
//  Inferencer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import TalkTalkSyntax

struct InferenceVisitor: Visitor {
	typealias Context = InferenceContext
	typealias Value = Void

	func infer(_ syntax: [any Syntax]) -> InferenceContext {
		let context = InferenceContext(
			environment: Environment(),
			constraints: Constraints()
		)

		for syntax in syntax {
			do {
				try syntax.accept(self, context)
			} catch {
				context.addError(.unknownError(error.localizedDescription))
			}
		}

		return context
	}

	func handleVarLet(_ decl: any VarLetDecl, context: InferenceContext) throws {
		let typeVariable = context.freshTypeVariable(decl.name)

		if let value = decl.value {
			try value.accept(self, context)
			context.extend(decl, with: .type(.typeVar(typeVariable)))

			// Get the inferred type of the value from the environment
			switch context[value] {
			case let .type(valueType):
				context.unify(.typeVar(typeVariable), valueType)
			case let .scheme(scheme):
				let type = context.instantiate(scheme: scheme)
				context.unify(.typeVar(typeVariable), type)
			default:
				fatalError("need to figure this out")
			}
		} else {
			try decl.typeExpr?.accept(self, context)

			if let typeExpr = decl.typeExpr {
				switch context[typeExpr] {
				case let .type(valueType):
					context.unify(.typeVar(typeVariable), valueType)
				case let .scheme(scheme):
					let type = context.instantiate(scheme: scheme)
					context.unify(.typeVar(typeVariable), type)
				default:
					fatalError("need to figure this out")
				}
			}

			context.extend(decl, with: .type(.typeVar(typeVariable)))
		}
	}

	func handleFuncLike(_ decl: any FuncLike, context: InferenceContext) throws {
		let childContext = context.childContext()

		// Create type variable for parameters and extend them to the environment
		// TODO: should we be creating a new context?
		var params: [InferenceType] = []
		for param in decl.params.params {
			let typeVariable = childContext.freshTypeVariable(param.name)
			params.append(.typeVar(typeVariable))
			childContext.extend(param, with: .type(.typeVar(typeVariable)))
		}

		// Create a temporary type variable for the function itself to allow for recursion
		let returning = InferenceType.typeVar(context.freshTypeVariable())
		var temporaryFn = InferenceType.function(params, returning)

		if let name = decl.name?.lexeme {
			let funcNameVar = context.freshTypeVariable(name)

			context.extend(decl, with: .type(.typeVar(funcNameVar)))
			context.unify(.typeVar(funcNameVar), temporaryFn)

			childContext.extend(decl, with: .type(temporaryFn))
			childContext.unify(.typeVar(funcNameVar), temporaryFn)

			temporaryFn = childContext.applySubstitutions(to: temporaryFn)
		}

		let returns = try childContext.trackReturns {
			try visit(decl.body, childContext)
		}

		// TODO: make sure returns agree
		guard case let .type(bodyType) = returns.first ?? childContext[decl.body] else {
			fatalError("did not get body type")
		}

		let functionType = InferenceType.function(params, bodyType)
		let scheme = Scheme(
			name: decl.name?.lexeme,
			variables: params.filter { childContext.isFreeVariable($0) },
			type: functionType
		)

		context.bind(typeVar: context.freshTypeVariable(decl.name?.lexeme), to: functionType)
		context.extend(decl, with: .scheme(scheme))
	}

	// Visits

	func visit(_ expr: CallExprSyntax, _ context: InferenceContext) throws {
		try expr.callee.accept(self, context)

		// Create a separate child context for evaluating arguments (to prevent leaks)
		let childContext = context.childContext()

		// Extract the function type or instantiate if it's a scheme
		var callee: InferenceType? = switch context[expr.callee] {
		case let .type(type):
			type
		case let .scheme(scheme):
			childContext.instantiate(scheme: scheme)
		default:
			nil
		}

		if let foundCallee = callee {
			callee = childContext.applySubstitutions(to: foundCallee)
		}

		var returns: InferenceType
		var parameters: [InferenceType]

		switch callee {
		case let .function(funcParams, funcReturns):
			parameters = funcParams
			returns = funcReturns
		case let .structType(structType):
			// TODO: Use the struct's init here, or synthesize one
			let initializer = structType.initializers["init"]

			switch initializer {
			case .scheme(let scheme):
				if case let .function(params, _) = context.instantiate(scheme: scheme) {
					parameters = params
				} else {
					context.addError(.unknownError("init was not a func"), to: expr)
					parameters = []
				}
			case .type(.function(let params, _)):
				parameters = params
			default:
				parameters = structType.properties.map { $0.value.asType! }
			}

			returns = .structInstance(structType)
		default:
			context.extend(expr, with: .type(.error(.typeError("Callee not callable: \(callee?.description ?? "nope")"))))
			return
		}

		if parameters.count != expr.args.count {
			context.extend(expr, with: .type(.error(.argumentError("Expected \(parameters.count) arguments, got \(expr.args.count)"))))
			return
		}

		// Infer and unify each argument's type with the corresponding parameter type
		for (argExpr, paramType) in zip(expr.args, parameters) {
			try argExpr.accept(self, childContext) // Infer the argument type

			if case let .type(argType) = childContext[argExpr] {
				context.unify(argType, paramType) // Unify argument type with the parameter type
			} else {
				context.extend(expr, with: .type(.error(.argumentError("Could not determine argument/parameter agreement"))))
			}
		}

		// Set the return type in the environment
		let finalReturns = context.applySubstitutions(to: returns)
		context.extend(expr, with: .type(finalReturns))
	}

	func visit(_ expr: DefExprSyntax, _ context: InferenceContext) throws {
		// This just returns void, but we should verify assignability at some point
		context.extend(expr, with: .type(.void))
	}

	func visit(_ expr: IdentifierExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: LiteralExprSyntax, _ context: InferenceContext) throws {
		switch expr.value {
		case .int:
			context.extend(expr, with: .type(.base(.int)))
		case .bool:
			context.extend(expr, with: .type(.base(.bool)))
		case .string:
			context.extend(expr, with: .type(.base(.string)))
		case .none:
			context.extend(expr, with: .type(.base(.nope)))
		}
	}

	func visit(_ expr: VarExprSyntax, _ context: InferenceContext) throws {
		if let variable = context.lookupVariable(named: expr.name) {
			context.extend(expr, with: .type(variable))
		} else {
			context.addError(.undefinedVariable(expr.name + ", ln: \(expr.location.line)"), to: expr)
		}
	}

	func visit(_ expr: UnaryExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: BinaryExprSyntax, _ context: InferenceContext) throws {
		try expr.lhs.accept(self, context)
		try expr.rhs.accept(self, context)

		guard case let .type(lhs) = context[expr.lhs] else {
			fatalError("did not get type for binary expr lhs")
		}

		guard case let .type(rhs) = context[expr.rhs] else {
			fatalError("did not get type for binary expr rhs")
		}

		context.unify(lhs, rhs)
		guard let constraint = context.constraints.map[.infixOperator(expr.op)]?[lhs] else {
			context.addError(.missingConstraint(lhs, .infixOperator(expr.op)), to: expr)
			return
		}

		let type = switch constraint.check(lhs, with: [rhs]) {
		case let .error(error):
			context.addError(error)
		case let .ok(returns):
			returns
		}

		context.extend(expr, with: .type(type))
	}

	func visit(_ expr: IfExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: WhileStmtSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: BlockStmtSyntax, _ context: InferenceContext) throws {
		for stmt in expr.stmts {
			try stmt.accept(self, context)
		}

		if let stmt = expr.stmts.last {
			context.extend(expr, with: context[stmt]!)
		} else {
			context.extend(expr, with: .type(.void))
		}
	}

	func visit(_ expr: FuncExprSyntax, _ context: InferenceContext) throws {
		try handleFuncLike(expr, context: context)
	}

	func visit(_ expr: ParamsExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: ParamSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: GenericParamsSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: CallArgument, _ context: InferenceContext) throws {
		try expr.value.accept(self, context)
		context.extend(expr, with: context[expr.value]!)
	}

	func visit(_ expr: StructExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: DeclBlockSyntax, _ context: InferenceContext) throws {
		for decl in expr.decls {
			try decl.accept(self, context)

			// If we're inside a type, we want to save this as a method or property
			if let typeContext = context.typeContext {
				switch (decl, context[decl]) {
				case let (decl as FuncExpr, .scheme):
					typeContext.methods[decl.autoname] = context[decl]
				case let (decl as FuncExpr, .type(.function)):
					typeContext.methods[decl.autoname] = context[decl]
				case let (decl as InitDecl, .scheme):
					typeContext.initializers["init"] = context[decl]
				case let (decl as VarLetDecl, .type(.structType(structType))):
					typeContext.properties[decl.name] = .type(.structInstance(structType))
				case let (decl as VarLetDecl, .type):
					typeContext.properties[decl.name] = context[decl]
				default:
					return
				}
			}
		}
	}

	func visit(_ expr: VarDeclSyntax, _ context: InferenceContext) throws {
		try handleVarLet(expr, context: context)
	}

	func visit(_ expr: LetDeclSyntax, _ context: InferenceContext) throws {
		try handleVarLet(expr, context: context)
	}

	func visit(_ expr: ParseErrorSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: MemberExprSyntax, _ context: InferenceContext) throws {
		try expr.receiver.accept(self, context)

		let structType: StructType? = switch context[expr.receiver] {
		case .type(.structInstance(let structType)):
			structType
		case .type(.structType(let structType)):
			structType
		default:
			nil
		}

		guard let structType else {
			context.extend(expr, with: .type(.error(.typeError("could not determine receiver: \(expr), got: \(context[expr.receiver] as Any)"))))
			return
		}

		let member = structType.methods[expr.property] ?? structType.properties[expr.property]

		switch member {
		case let .scheme(scheme):
			let instantiated = context.instantiate(scheme: scheme)
			let substitutedMember = context.applySubstitutions(to: instantiated)
			context.extend(expr, with: .type(substitutedMember))
		case let .type(type):
			let substitutedMember = context.applySubstitutions(to: type)
			context.extend(expr, with: .type(substitutedMember))
		default:
			context.extend(expr, with: .type(.error(.memberNotFound(structType, expr.property))))
		}
	}

	func visit(_ expr: ReturnStmtSyntax, _ context: InferenceContext) throws {
		if let value = expr.value {
			try value.accept(self, context)
			context.extend(expr, with: context[value]!)
			context.trackReturn(context[value]!)
		} else {
			context.extend(expr, with: .type(.void))
			context.trackReturn(.type(.void))
		}
	}

	func visit(_ expr: InitDeclSyntax, _ context: InferenceContext) throws {
		guard let typeContext = context.typeContext else {
			context.addError(.unknownError("cannot define init() outside type context"), to: expr)
			return
		}

		try handleFuncLike(expr, context: context)

		// TODO: Support multiple initializers
		// TODO: Ensure all properties are initialized
		typeContext.initializers["init"] = context[expr]
	}

	func visit(_ expr: ImportStmtSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: TypeExprSyntax, _ context: InferenceContext) throws {
		switch expr.identifier.lexeme {
		case "int":
			context.extend(expr, with: .type(.base(.int)))
		case "bool":
			context.extend(expr, with: .type(.base(.bool)))
		case "String":
			context.extend(expr, with: .type(.base(.string)))
		default:
			if let type = context.lookupVariable(named: expr.identifier.lexeme) {
				context.extend(expr, with: .type(type))
			} else {
				context.extend(expr, with: .type(.error(.typeError("Type not found: \(expr.identifier.lexeme)"))))
			}
		}
	}

	func visit(_ expr: ExprStmtSyntax, _ context: InferenceContext) throws {
		try expr.expr.accept(self, context)
		context.extend(expr, with: context[expr.expr]!)
	}

	func visit(_ expr: IfStmtSyntax, _ context: InferenceContext) throws {
		try expr.condition.accept(self, context)
		try expr.consequence.accept(self, context)
		try expr.alternative?.accept(self, context)

		context.extend(expr, with: .type(.void))
	}

	func visit(_ expr: StructDeclSyntax, _ context: InferenceContext) throws {
		// Define an inference context for this struct's body to be inferred in
		let structContext = context.childTypeContext()

		// Visit the body with the new context. Property decls and function definitions
		// will be added as substitutions at this time, then we can pull them out after
		// we're done parsing the body.
		try visit(expr.body, structContext)

		let structType = StructType(
			name: expr.name,
			parameters: [],
			methods: structContext.typeContext!.methods,
			properties: structContext.typeContext!.properties,
			initializers: structContext.typeContext!.initializers,
			context: structContext
		)
		context.extend(expr, with: .type(.structType(structType)))
	}

	func visit(_ expr: ArrayLiteralExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: SubscriptExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: DictionaryLiteralExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}

	func visit(_ expr: DictionaryElementExprSyntax, _ context: InferenceContext) throws {
		fatalError("TODO")
	}
}
