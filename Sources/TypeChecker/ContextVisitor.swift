//
//  ContextVisitor.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/1/24.
//
import TalkTalkCore

enum TypeError: Error {
	case undefinedVariable(String)
	case typeError(String)
}

struct ContextVisitor: Visitor {
	typealias Context = TypeChecker.Context
	typealias Value = InferenceResult

	static func visit(_ syntax: [any Syntax], imports: [Context] = [], verbose: Bool = false) throws -> Context {
		let context = Context(lexicalScope: nil, imports: imports, verbose: verbose)
		let visitor = ContextVisitor()

		// Do a breadth first traversal to find names
		visitor.findNames(syntax: syntax, context: context)

		for syntax in syntax {
			_ = try syntax.accept(visitor, context)
		}

		return context
	}

	// MARK: Helpers

	func findNames(syntax: [any Syntax], context: Context) {
		// Just go through the syntax here and create placeholders for decls if we don't know about them already
		for decl in syntax where decl is Decl {
			switch decl {
			case let decl as EnumDecl:
				let typeVar = context.freshTypeVariable(decl.nameToken.lexeme)
				context.define(decl.nameToken.lexeme, as: .type(.placeholder(typeVar)))
			case let decl as StructDecl:
				let typeVar = context.freshTypeVariable(decl.name)
				context.define(decl.nameToken.lexeme, as: .type(.placeholder(typeVar)))
			case let decl as ProtocolDecl:
				let typeVar = context.freshTypeVariable(decl.name.lexeme)
				context.define(decl.name.lexeme, as: .type(.placeholder(typeVar)))
			case let funcDecl as FuncExprSyntax:
				if let name = funcDecl.name?.lexeme {
					let typeVar = context.freshTypeVariable(name)
					context.define(name, as: .type(.placeholder(typeVar)))
				}
			default:
				()
			}
		}
	}

	func handleVarLet(_ syntax: VarLetDecl, context: Context) throws -> InferenceResult {
		if let existing = context.type(named: syntax.name, includeParents: false, includeBuiltins: false) {
			context.error("Variable \(syntax.name) is already defined as \(existing)", at: syntax.location)
		}

		let typeExpr = try syntax.typeExpr.flatMap { try $0.accept(self, context) }
		let value = try syntax.value.flatMap { try $0.accept(self, context) }

		let type: InferenceResult

		switch (typeExpr, value) {
		case (.none, .none):
			type = .type(.typeVar(context.freshTypeVariable(syntax.name)))
		case let (nil, .some(value)):
			type = value
		case let (.some(typeExpr), nil):
			type = typeExpr
		case let (.some(typeExpr), .some(.type(.typeVar(typeVariable)))):
			context.addConstraint(Constraints.Equality(context: context, lhs: typeExpr, rhs: .type(.typeVar(typeVariable)), location: syntax.location))
			type = typeExpr
		case let (.some(typeExpr), .some(value)):
			if typeExpr != value {
				context.error("\(value) cannot be assigned to \(typeExpr)", at: syntax.location)
			}

			type = typeExpr
		}

		context.define(syntax.name, as: type)

		// Decls return void
		return .type(.void)
	}

	// MARK: Visits

	func visit(_ syntax: CallExprSyntax, _ context: Context) throws -> InferenceResult {
		let callee = try syntax.callee.accept(self, context)
		let args = try syntax.args.map { try $0.accept(self, context) }
		let returns: InferenceResult = .type(.typeVar(context.freshTypeVariable(syntax.description)))

		context.addConstraint(
			Constraints.Call(context: context, callee: callee, args: args, result: returns, location: syntax.location)
		)

		context.define(syntax, as: returns)

		return returns
	}

	func visit(_ syntax: DefExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: IdentifierExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: LiteralExprSyntax, _ context: Context) throws -> InferenceResult {
		let result: InferenceResult

		switch syntax.value {
		case .int:
			result = .type(.base(.int))
		case .bool:
			result = .type(.base(.bool))
		case .string:
			result = .type(.base(.string))
		case .nil:
			result = .type(.base(.none))
		}

		context.define(syntax, as: result)

		return result
	}

	func visit(_ syntax: VarExprSyntax, _ context: Context) throws -> InferenceResult {
		if let result = context.type(named: syntax.name) {
			context.define(syntax, as: result)
			return result
		}

		context.error("Undefined variable: `\(syntax.name)`", at: syntax.location)
		return .type(.any)
	}

	func visit(_ syntax: UnaryExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: BinaryExprSyntax, _ context: Context) throws -> InferenceResult {
		let lhs = try syntax.lhs.accept(self, context)
		let rhs = try syntax.rhs.accept(self, context)

		let type = context.freshTypeVariable(syntax.description)
		context.define(syntax, as: .type(.typeVar(type)))

		context.addConstraint(
			Constraints.Infix(context: context, lhs: lhs, rhs: rhs, op: syntax.op, result: type, location: syntax.location)
		)

		return .type(.typeVar(type))
	}

	func visit(_ syntax: IfExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: WhileStmtSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: BlockStmtSyntax, _ context: Context) throws -> InferenceResult {
		var stmts: [InferenceResult] = []

		for stmt in syntax.stmts {
			try stmts.append(stmt.accept(self, context))
		}

		return stmts.last ?? .type(.void)
	}

	func visit(_ syntax: FuncExprSyntax, _ context: Context) throws -> InferenceResult {
		let childContext = context.addChild()

		_ = try visit(syntax.params, childContext)
		let body = try syntax.body.accept(self, childContext)

		var annotatedReturn: InferenceResult? = nil
		if let typeDecl = syntax.typeDecl {
			annotatedReturn = try typeDecl.accept(self, context)
		}

		// TODO: Make sure these agree
		let returns = annotatedReturn ?? childContext.explicitReturns.last ?? body

		var typeVariables: [TypeVariable] = []
		let params: [InferenceType] = try syntax.params.params.map {
			guard let type = childContext[$0] else {
				throw TypeError.undefinedVariable($0.name)
			}

			if case let .typeVar(typeVar) = type {
				typeVariables.append(typeVar)
			}

			return type
		}

		// If the return type is a type variable, hoist it into the context so we can use it for the definition
		if case let .type(.typeVar(returns)) = returns {
			typeVariables.append(returns)
		}

		let result: InferenceResult
		if typeVariables.isEmpty {
			result = .type(.function(params.map { .type($0) }, returns))
		} else {
			result = .scheme(Scheme(name: syntax.name?.lexeme, variables: typeVariables, type: .function(params.map { .type($0) }, returns)))
		}

		// Hoist unknown params into this context for the function definition
		for typeVar in typeVariables {
			childContext.hoistedToParent.insert(typeVar)
		}

		if let name = syntax.name?.lexeme {
			context.define(name, as: result)
			childContext.define(name, as: result)
		}

		context.define(syntax, as: result)
		return result
	}

	func visit(_ syntax: ParamsExprSyntax, _ context: Context) throws -> InferenceResult {
		for param in syntax.params {
			_ = try visit(param, context)
		}

		return .type(.void)
	}

	func visit(_ syntax: ParamSyntax, _ context: Context) throws -> InferenceResult {
		let result: InferenceResult

		if let type = syntax.type {
			result = try visit(type, context)
		} else {
			let typeVar = context.freshTypeVariable(syntax.name)
			result = .type(.typeVar(typeVar))
		}

		context.define(syntax.name, as: result)
		context.define(syntax, as: result)

		return result
	}

	func visit(_ syntax: GenericParamsSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: Argument, _ context: Context) throws -> InferenceResult {
		try syntax.value.accept(self, context)
	}

	func visit(_ syntax: StructExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: DeclBlockSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: VarDeclSyntax, _ context: Context) throws -> InferenceResult {
		try handleVarLet(syntax, context: context)
	}

	func visit(_ syntax: LetDeclSyntax, _ context: Context) throws -> InferenceResult {
		try handleVarLet(syntax, context: context)
	}

	func visit(_ syntax: ParseErrorSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: MemberExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: ReturnStmtSyntax, _ context: Context) throws -> InferenceResult {
		if let returns = try syntax.value?.accept(self, context) {
			context.explicitReturns.append(returns)
			context.define(syntax, as: returns)
			return returns
		} else {
			context.define(syntax, as: .type(.void))
			return .type(.void)
		}
	}

	func visit(_ syntax: InitDeclSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: ImportStmtSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: TypeExprSyntax, _ context: Context) throws -> InferenceResult {
		if let type = context.type(named: syntax.identifier.lexeme) {
			return type
		} else {
			context.error("Type not found: \(syntax.identifier.lexeme)", at: syntax.location)
			return .type(.any)
		}
	}

	func visit(_ syntax: ExprStmtSyntax, _ context: Context) throws -> InferenceResult {
		let result = try syntax.expr.accept(self, context)
		context.define(syntax, as: result)
		return result
	}

	func visit(_ syntax: IfStmtSyntax, _ context: Context) throws -> InferenceResult {
		_ = try syntax.condition.accept(self, context)
		_ = try syntax.consequence.accept(self, context)
		_ = try syntax.alternative?.accept(self, context)

		return .type(.void)
	}

	func visit(_ syntax: StructDeclSyntax, _ context: Context) throws -> InferenceResult {
		let structType = StructType(name: syntax.name)
		let structContext = context.addChild(lexicalScope: structType)

		for decl in syntax.body.decls {
			_ = try decl.accept(self, structContext)
		}

		// We use a Scheme for structs because they can contain generic type variables
		let result = InferenceResult.scheme(
			Scheme(name: syntax.name, variables: [], type: .struct(structType))
		)

		// Define the struct by name
		context.define(syntax.name, as: result)
		context.define(syntax, as: result)

		return result
	}

	func visit(_ syntax: ArrayLiteralExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: SubscriptExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: DictionaryLiteralExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: DictionaryElementExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: ProtocolDeclSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: ProtocolBodyDeclSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: FuncSignatureDeclSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: EnumDeclSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: EnumCaseDeclSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: MatchStatementSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: CaseStmtSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: EnumMemberExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: InterpolatedStringExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: ForStmtSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: LogicalExprSyntax, _ context: Context) throws -> InferenceResult {
		let lhs = try syntax.lhs.accept(self, context)
		let rhs = try syntax.rhs.accept(self, context)

		context.addConstraint(Constraints.Equality(context: context, lhs: lhs, rhs: rhs, location: syntax.location))

		context.define(syntax, as: .type(.base(.bool)))
		return .type(.base(.bool))
	}

	func visit(_ syntax: GroupedExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: LetPatternSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: PropertyDeclSyntax, _ context: Context) throws -> InferenceResult {
		guard let lexicalScope = context.lexicalScope else {
			context.error("Could not find lexical scope for property: `\(syntax.name)`", at: syntax.location)
			return .type(.any)
		}

		let name = syntax.name.lexeme

		let annotatedType = try syntax.typeAnnotation.flatMap {
			try $0.accept(self, context)
		}

		let valueType = try syntax.defaultValue.flatMap {
			try $0.accept(self, context)
		}

		if let annotatedType, let valueType {
			// If we've got both an annotated type and a default value, make sure they match
			context.addConstraint(Constraints.Equality(context: context, lhs: annotatedType, rhs: valueType, location: syntax.location))
		}

		let result = annotatedType ?? valueType ?? .type(.typeVar(context.freshTypeVariable("\(lexicalScope.name).\(syntax.name)")))
		try lexicalScope.add(member: result, named: name)

		return .type(.void)
	}
}
