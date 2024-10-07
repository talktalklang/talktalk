//
//  ContextVisitor.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/1/24.
//
import TalkTalkCore
import Foundation

enum TypeError: Error, LocalizedError {
	case undefinedVariable(String)
	case typeError(String)

	var errorDescription: String? {
		switch self {
		case .undefinedVariable(let name):
			return "Undefined variable: \(name)"
		case .typeError(let message):
			return message
		}
	}
}

public struct Typer {
	let imports: [Context]
	public let context: Context

	static func compileStandardLibrary(verbose: Bool = false) throws -> Context {
		let files = Library.standard.files.flatMap { try! Parser.parse($0) }
		let context = try ContextVisitor.visit(files, module: "Standard", verbose: verbose)

		if !context.diagnostics.isEmpty {
			throw TypeError.typeError("Could not compile standard library: \(context.diagnostics.map(\.message))")
		}

		return context
	}

	nonisolated(unsafe) static let stdlib: Context = {
		try! Self.compileStandardLibrary()
	}()

	public init(module: String, imports: [Context], verbose: Bool = false, debugStdlib: Bool = false) throws {
		// Prepend the standard library
		var imports = imports

		if module != "Standard" {
			imports = [Self.stdlib] + imports
		}

		self.imports = imports
		self.context = Context(
			module: module,
			parent: nil,
			lexicalScope: nil,
			imports: imports,
			verbose: verbose
		)
	}

	public func solve(_ syntax: [any Syntax]) throws -> Context {
		let visitor = ContextVisitor()
		visitor.findNames(syntax: syntax, context: context)

		for syntax in syntax {
			_ = try syntax.accept(visitor, context)
		}

		return context.solve()
	}
}

struct ContextVisitor: Visitor {
	typealias Context = TypeChecker.Context
	typealias Value = InferenceResult

	static func visit(_ syntax: [any Syntax], module: String, imports: [Context] = [], verbose: Bool = false) throws -> Context {
		let context = Context(module: module, lexicalScope: nil, imports: imports, verbose: verbose)
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
				context.define(decl.nameToken.lexeme, as: .resolved(.placeholder(typeVar)))
			case let decl as StructDecl:
				let typeVar = context.freshTypeVariable(decl.name)
				context.define(decl.nameToken.lexeme, as: .resolved(.placeholder(typeVar)))
			case let decl as ProtocolDecl:
				let typeVar = context.freshTypeVariable(decl.name.lexeme)
				context.define(decl.name.lexeme, as: .resolved(.placeholder(typeVar)))
			case let funcDecl as FuncExprSyntax:
				if let name = funcDecl.name?.lexeme {
					let typeVar = context.freshTypeVariable(name)
					context.define(name, as: .resolved(.placeholder(typeVar)))
				}
			default:
				()
			}
		}
	}

	func handleFuncLike(_ syntax: any FuncLike, context: Context) throws -> InferenceResult {
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
		if case let .resolved(.typeVar(returns)) = returns {
			typeVariables.append(returns)
		}

		let result: InferenceResult
		if typeVariables.isEmpty {
			result = .resolved(.function(params.map { .resolved($0) }, returns))
		} else {
			result = .scheme(Scheme(name: syntax.name?.lexeme, variables: typeVariables, type: .function(params.map { .resolved($0) }, returns)))
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

	func handleVarLetDecl(_ syntax: VarLetDecl, context: Context) throws -> InferenceResult {
		if let existing = context.type(named: syntax.name, includeParents: false, includeBuiltins: false) {
			context.error("Variable \(syntax.name) is already defined as \(existing)", at: syntax.location)
		}

		let typeExpr = try syntax.typeExpr.flatMap {
			var result = try visit($0, context)

			if case let .resolved(.type(type)) = result {
				result = .resolved(.instance(type.instantiate(with: [:])))
			}

			return result
		}

		let value = try syntax.value.flatMap { try $0.accept(self, context) }
		let type: InferenceResult

		switch (typeExpr, value) {
		case (.none, .none):
			type = .resolved(.typeVar(context.freshTypeVariable(syntax.name)))
		case let (nil, .some(value)):
			type = value
		case let (.some(typeExpr), nil):
			type = typeExpr
		case let (.some(typeExpr), .some(.resolved(.typeVar(typeVariable)))):
			context.addConstraint(Constraints.Equality(context: context, lhs: typeExpr, rhs: .resolved(.typeVar(typeVariable)), location: syntax.location))
			type = typeExpr
		case let (.some(typeExpr), .some(value)):
			context.addConstraint(Constraints.Equality(context: context, lhs: value, rhs: typeExpr, location: syntax.location))

			type = typeExpr
		}

		context.define(syntax.name, as: type)

		// Decls return void
		return .resolved(.void)
	}

	// Try to look up a member from an inference result. If we can find one, we can avoid going through the typevar/constraint
	// dance. Important to know that we don't want to do any instantiation here, since that should only happen in constraints,
	// otherwise we can end up with redundant type variables.
	func member(from receiver: InferenceResult, named name: String) -> InferenceResult? {
		switch receiver {
		case .scheme(let scheme):
			return member(from: .resolved(scheme.type), named: name)
		case .resolved(let type):
			switch type {
			case let .type(.enum(enumType)):
				return enumType.staticMember(named: name)
			case let .type(.enumCase(kase)):
				return kase.type.staticMember(named: name)
			case let .instance(wrapper):
				return wrapper.member(named: name)
			case let .self(wrapped):
				return wrapped.member(named: name)
			case let .type(.protocol(type)):
				return type.member(named: name)
			default:
				return nil
			}
		}
	}

	func parameters(for callee: InferenceResult) -> [InferenceResult]? {
		switch callee {
		case .scheme(let scheme):
			return parameters(for: .resolved(scheme.type))
		case .resolved(let type):
			switch type {
			case .function(let params, _):
				return params
			case .type(.enumCase(let kase)):
				return kase.attachedTypes
			default:
				return nil
			}
		}
	}

	func returnResult(for result: InferenceResult) -> InferenceResult? {
		switch result {
		case .scheme(_):
			return nil
		case .resolved(let type):
			switch type {
			case .function(_, let returns):
				return returns
			case .type(.enumCase(let kase)):
				return .resolved(.instance(.enumCase(Instance(type: kase))))
			default:
				return nil
			}
		}
	}

	func unwrapped(_ result: InferenceResult, in context: Context, location: SourceLocation) -> InferenceResult {
		switch result {
		case .scheme(_):
			return result
		case .resolved(let type):
			switch type {
			case .instance(.enum(let instance)):
				let wrapped = instance.type.typeParameters["Wrapped"]!
				return .resolved(instance.substitutions[wrapped]!)
			default:
				let typeVar = context.freshTypeVariable("\(result)!")

				context.addConstraint(
					Constraints.Unwrap(context: context, value: result, unwrapped: typeVar, location: location)
				)

				return .resolved(.typeVar(typeVar))
			}
		}
	}

	func createTypeParameters<T: MemberOwner>(_ typeExprs: [TypeExprSyntax], for type: inout T, in context: Context) -> [TypeVariable] {
		typeExprs.map {
			let typeVar = context.freshTypeVariable($0.identifier.lexeme, isGeneric: true)
			context.define($0.identifier.lexeme, as: .resolved(.typeVar(typeVar)))
			type.typeParameters[$0.identifier.lexeme] = typeVar
			return typeVar
		}
	}

	func ensureConformances<T: MemberOwner>(_ conformances: [TypeExprSyntax], for type: T, in context: Context) {
		for conformance in conformances {
			guard let conformsTo = context.type(named: conformance.identifier.lexeme) else {
				context.error("Could not find protocol `\(conformance.identifier.lexeme)`", at: conformance.location)
				continue
			}

			context.addConstraint(
				Constraints.Conformance(
					context: context,
					type: .resolved(.type(type.wrapped)),
					conformsTo: conformsTo,
					location: conformance.location
				)
			)
		}
	}

	// MARK: Visits

	func visit(_ syntax: CallExprSyntax, _ context: Context) throws -> InferenceResult {
		let callee = try syntax.callee.accept(self, context)

		let args = if let parameters = parameters(for: callee) {
			try zip(syntax.args, parameters).map { (arg, param) in
				try context.expecting(param) {
					try visit(arg, context)
				}
			}
		} else {
			try syntax.args.map {
				try visit($0, context)
			}
		}

		let returns: InferenceResult = returnResult(for: callee) ?? .resolved(.typeVar(context.freshTypeVariable(callee.description)))

		context.addConstraint(
			Constraints.Call(
				context: context,
				callee: callee,
				args: args,
				result: returns,
				location: syntax.location
			)
		)

		context.define(syntax, as: returns)

		return returns
	}

	func visit(_ syntax: DefExprSyntax, _ context: Context) throws -> InferenceResult {
		let receiver = try syntax.receiver.accept(self, context)
		let value = try syntax.value.accept(self, context)

		context.addConstraint(
			Constraints.Equality(
				context: context,
				lhs: receiver,
				rhs: value,location: syntax.location
			)
		)

		return value
	}

	func visit(_ syntax: IdentifierExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: LiteralExprSyntax, _ context: Context) throws -> InferenceResult {
		let result: InferenceResult

		switch syntax.value {
		case .int:
			result = .resolved(.base(.int))
		case .bool:
			result = .resolved(.base(.bool))
		case .string:
			result = .resolved(.base(.string))
		case .nil:
			result = .resolved(.base(.none))
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
		return .resolved(.any)
	}

	func visit(_ syntax: UnaryExprSyntax, _ context: Context) throws -> InferenceResult {
		// TODO: Validate here
		switch syntax.op.kind {
		case .bang:
			return .resolved(.base(.bool))
		case .minus:
			return .resolved(.base(.int))
		default:
			context.error("Invalid unary operator: \(syntax.op.kind)", at: syntax.location)
			return .resolved(.void)
		}
	}

	func visit(_ syntax: BinaryExprSyntax, _ context: Context) throws -> InferenceResult {
		let lhs = try syntax.lhs.accept(self, context)
		let rhs = try syntax.rhs.accept(self, context)

		let type = context.freshTypeVariable(syntax.description)
		context.define(syntax, as: .resolved(.typeVar(type)))

		context.addConstraint(
			Constraints.Infix(context: context, lhs: lhs, rhs: rhs, op: syntax.op, result: type, location: syntax.location)
		)

		return .resolved(.typeVar(type))
	}

	func visit(_ syntax: IfExprSyntax, _ context: Context) throws -> InferenceResult {
		let consequenceContext = context.addChild()

		_ = try syntax.condition.accept(self, consequenceContext)
		let consequence = try syntax.consequence.accept(self, consequenceContext)
		let alternative = try syntax.alternative.accept(self, context)

		context.addConstraint(
			Constraints.Equality(context: context, lhs: consequence, rhs: alternative, location: syntax.location)
		)

		return consequence
	}

	func visit(_ syntax: WhileStmtSyntax, _ context: Context) throws -> InferenceResult {
		_ = try syntax.condition.accept(self, context)
		_ = try syntax.body.accept(self, context)

		context.define(syntax, as: .resolved(.void))

		return .resolved(.void)
	}

	func visit(_ syntax: BlockStmtSyntax, _ context: Context) throws -> InferenceResult {
		var stmts: [InferenceResult] = []

		for stmt in syntax.stmts {
			try stmts.append(stmt.accept(self, context))
		}

		return stmts.last ?? .resolved(.void)
	}

	func visit(_ syntax: FuncExprSyntax, _ context: Context) throws -> InferenceResult {
		try handleFuncLike(syntax, context: context)
	}

	func visit(_ syntax: ParamsExprSyntax, _ context: Context) throws -> InferenceResult {
		for param in syntax.params {
			_ = try visit(param, context)
		}

		return .resolved(.void)
	}

	func visit(_ syntax: ParamSyntax, _ context: Context) throws -> InferenceResult {
		var result: InferenceResult

		if let type = syntax.type {
			result = try visit(type, context)
		} else {
			let typeVar = context.freshTypeVariable(syntax.name)
			result = .resolved(.typeVar(typeVar))
		}

		if case let .resolved(.type(type)) = result {
			// If the result type can be instantiated, it should be an instance
			result = .resolved(.instance(type.instantiate(with: [:])))
		}

		context.define(syntax.name, as: result)
		context.define(syntax, as: result)

		return result
	}

	func visit(_ syntax: GenericParamsSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: Argument, _ context: Context) throws -> InferenceResult {
		let result = try syntax.value.accept(self, context)
		context.define(syntax, as: result)
		return result
	}

	func visit(_ syntax: StructExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: DeclBlockSyntax, _ context: Context) throws -> InferenceResult {
		for decl in syntax.decls {
			_ = try decl.accept(self, context)
		}

		return .resolved(.void)
	}

	func visit(_ syntax: VarDeclSyntax, _ context: Context) throws -> InferenceResult {
		try handleVarLetDecl(syntax, context: context)
	}

	func visit(_ syntax: LetDeclSyntax, _ context: Context) throws -> InferenceResult {
		try handleVarLetDecl(syntax, context: context)
	}

	func visit(_ syntax: ParseErrorSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: MemberExprSyntax, _ context: Context) throws -> InferenceResult {
		let receiver = try syntax.receiver?.accept(self, context) ?? context.expectedType

		// If we have enough information to get the member here, we should so we don't need to go through
		// the typevar/contraint process.
		if let receiver, let member = member(from: receiver, named: syntax.property) {
			context.define(syntax, as: member)

			return member
		} else {
			let result = context.freshTypeVariable("\(syntax.receiver?.description ?? "").\(syntax.property)")

			context.addConstraint(
				Constraints.Member(
					receiver: receiver,
					expectedType: context.expectedType,
					memberName: syntax.property,
					result: result,
					context: context,
					location: syntax.location
				)
			)

			context.define(syntax, as: .resolved(.typeVar(result)))

			return .resolved(.typeVar(result))
		}
	}

	func visit(_ syntax: ReturnStmtSyntax, _ context: Context) throws -> InferenceResult {
		if let returns = try syntax.value?.accept(self, context) {
			context.explicitReturns.append(returns)
			context.define(syntax, as: returns)
			return returns
		} else {
			context.define(syntax, as: .resolved(.void))
			return .resolved(.void)
		}
	}

	func visit(_ syntax: InitDeclSyntax, _ context: Context) throws -> InferenceResult {
		guard let lexicalScope = context.lexicalScope else {
			context.error("Initializer must be a function", at: syntax.location)
			return .resolved(.any)
		}

		let result = try handleFuncLike(syntax, context: context)
		try lexicalScope.add(member: result, named: "init", isStatic: false)

		context.define(syntax, as: result)

		return .resolved(.void)
	}

	func visit(_ syntax: ImportStmtSyntax, _ context: Context) throws -> InferenceResult {
		.resolved(.void)
	}

	func visit(_ syntax: TypeExprSyntax, _ context: Context) throws -> InferenceResult {
		if let type = context.type(named: syntax.identifier.lexeme) {
			guard case let .scheme(scheme) = type else {
				if syntax.isOptional {
					context.define(syntax, as: .optional(type))
					return .optional(type)
				} else {
					context.define(syntax, as: type)
					return type
				}
			}

			var substitutions: Substitutions = [:]
			for (typeParam, param) in zip(scheme.variables, syntax.genericParams) {
				let paramType = try param.accept(self, context)
				substitutions[typeParam] = paramType.instantiate(in: context).type
			}

			if syntax.isOptional {
				return .resolved(.optional(type.asInstance(in: context, with: substitutions)))
			} else {
				return .resolved(type.asInstance(in: context, with: substitutions))
			}

		} else {
			context.error("Type not found: \(syntax.identifier.lexeme)", at: syntax.location)
			return .resolved(.any)
		}
	}

	func visit(_ syntax: ExprStmtSyntax, _ context: Context) throws -> InferenceResult {
		let result = try syntax.expr.accept(self, context)
		context.define(syntax, as: result)
		return result
	}

	func visit(_ syntax: IfStmtSyntax, _ context: Context) throws -> InferenceResult {
		let consequenceContext = context.addChild()

		_ = try syntax.condition.accept(self, consequenceContext)
		_ = try syntax.consequence.accept(self, consequenceContext)
		_ = try syntax.alternative?.accept(self, context)

		return .resolved(.void)
	}

	func visit(_ syntax: StructDeclSyntax, _ context: Context) throws -> InferenceResult {
		var structType = StructType(name: syntax.name, module: context.module)
		let structContext = context.addChild(lexicalScope: structType)

		ensureConformances(syntax.conformances, for: structType, in: context)

		let variables = createTypeParameters(syntax.typeParameters, for: &structType, in: structContext)

		structContext.define("self", as: .scheme(
			Scheme(name: "self", variables: variables, type: .self(structType)))
		)

		for decl in syntax.body.decls {
			_ = try decl.accept(self, structContext)
		}

		// We use a Scheme for structs because they can contain generic type variables
		let result = InferenceResult.scheme(
			Scheme(name: syntax.name, variables: variables, type: .type(.struct(structType)))
		)

		// Define the struct by name
		context.define(syntax.name, as: result)
		context.define(syntax, as: result)

		return result
	}

	func visit(_ syntax: ArrayLiteralExprSyntax, _ context: Context) throws -> InferenceResult {
		guard case let .scheme(arrayScheme) = context.type(named: "Array"),
					case let .type(.struct(arrayType)) = arrayScheme.type else {
			context.error("Could not load builtin Array type", at: syntax.location)
			return .resolved(.error(.init(kind: .typeError("Could not load builtin array type"), location: syntax.location)))
		}

		let elements: [InferenceResult] = try syntax.exprs.map { try $0.accept(self, context) }
		let elementType = elements.first ?? .resolved(.typeVar((context.freshTypeVariable("Array<Element>"))))
		let elementTypeVar = arrayScheme.variables[0]
		let arrayInstance = Instance(
			type: arrayType,
			substitutions: [
				elementTypeVar: elementType.instantiate(in: context).type
			]
		)

		return .resolved(.instance(.struct(arrayInstance)))
	}

	func visit(_ syntax: SubscriptExprSyntax, _ context: Context) throws -> InferenceResult {
		let receiver = try syntax.receiver.accept(self, context)

		if case let .resolved(.instance(receiver)) = receiver {
			guard let getMethod = receiver.member(named: "get"),
						case let .function(_, returns) = getMethod.instantiate(in: context, with: receiver.substitutions).type else {
				context.error("No `get` method found for subscript receiver \(syntax.receiver.description)", at: syntax.receiver.location)
				return .resolved(.void)
			}

			context.define(syntax, as: returns)
			return returns
		} else {
			let args = try syntax.args.map { try $0.accept(self, context) }
			let result = context.freshTypeVariable(syntax.description)
			context.addConstraint(
				Constraints.Subscript(context: context, receiver: receiver, args: args, result: result, location: syntax.location)
			)

			context.define(syntax, as: .resolved(.typeVar(result)))
			return .resolved(.typeVar(result))
		}
	}

	func visit(_ syntax: DictionaryLiteralExprSyntax, _ context: Context) throws -> InferenceResult {
		guard case let .scheme(dictScheme) = context.type(named: "Dictionary"),
					case let .type(.struct(dictType)) = dictScheme.type else {
			context.error("Could not load builtin Dictionary type", at: syntax.location)
			return .resolved(.error(.init(kind: .typeError("Could not load builtin Dictionary type"), location: syntax.location)))
		}

		let elementKeyType: InferenceResult
		let elementKeyValue: InferenceResult

		if let element = syntax.elements.first {
			elementKeyType = try element.key.accept(self, context)
			elementKeyValue = try element.value.accept(self, context)
		} else {
			elementKeyType = .resolved(.typeVar((context.freshTypeVariable("Dictionary<Key>"))))
			elementKeyValue = .resolved(.typeVar((context.freshTypeVariable("Dictionary<Value>"))))
		}

		let elementKeyVar = dictScheme.variables[0]
		let elementValueVar = dictScheme.variables[1]

		let instance = Instance(
			type: dictType,
			substitutions: [
				elementKeyVar: elementKeyType.asInstance(in: context, with: [:]),
				elementValueVar: elementKeyValue.asInstance(in: context, with: [:])
			]
		)

		return .resolved(.instance(.struct(instance)))
	}

	func visit(_ syntax: DictionaryElementExprSyntax, _ context: Context) throws -> InferenceResult {
		.resolved(.void) // Handled by DictionaryLiteralExprSyntax
	}

	func visit(_ syntax: ProtocolDeclSyntax, _ context: Context) throws -> InferenceResult {
		let name = syntax.name.lexeme
		let protocolType = ProtocolType(name: name, module: context.module)
		let protocolContext = context.addChild(lexicalScope: protocolType)

		let variables = syntax.typeParameters.map {
			let typeVar = context.freshTypeVariable($0.identifier.lexeme, isGeneric: true)
			protocolContext.define($0.identifier.lexeme, as: .resolved(.typeVar(typeVar)))
			protocolType.typeParameters[$0.identifier.lexeme] = typeVar
			return typeVar
		}

		protocolContext.define("self", as: .scheme(
			Scheme(name: "self", variables: variables, type: .self(protocolType)))
		)

		_ = try visit(syntax.body, protocolContext)

		// Protocols can have generic types so we give them a scheme
		let result = InferenceResult.scheme(
			Scheme(
				name: name,
				variables: variables,
				type: .type(.protocol(protocolType))
			)
		)

		// Define the name
		context.define(name, as: result)
		protocolContext.define(name, as: result)

		// Define the node
		context.define(syntax, as: result)

		return result
	}

	func visit(_ syntax: ProtocolBodyDeclSyntax, _ context: Context) throws -> InferenceResult {
		for decl in syntax.decls {
			_ = try decl.accept(self, context)
		}

		return .resolved(.void)
	}

	func visit(_ syntax: FuncSignatureDeclSyntax, _ context: Context) throws -> InferenceResult {
		guard let lexicalScope = context.lexicalScope else {
			context.error("Could not find lexical scope for method: `\(syntax.nameToken.lexeme)`", at: syntax.location)
			return .resolved(.any)
		}

		let result = try handleFuncLike(syntax, context: context)
		let name = syntax.nameToken.lexeme
		try lexicalScope.add(member: result, named: name, isStatic: false)

		return .resolved(.void)
	}

	func visit(_ syntax: EnumDeclSyntax, _ context: Context) throws -> InferenceResult {
		let name = syntax.nameToken.lexeme
		var enumType = Enum(name: name, module: context.module, cases: [:])
		let enumContext = context.addChild(lexicalScope: enumType)

		ensureConformances(syntax.conformances, for: enumType, in: context)

		let variables = createTypeParameters(syntax.typeParams, for: &enumType, in: enumContext)

		enumContext.define("self", as: .scheme(
			Scheme(name: "self", variables: variables, type: .self(enumType)))
		)

		_ = try visit(syntax.body, enumContext)

		// Enums can have generic types so we give them a scheme
		let result = InferenceResult.scheme(
			Scheme(
				name: name,
				variables: variables,
				type: .type(.enum(enumType))
			)
		)

		// Define the name
		context.define(name, as: result)
		enumContext.define(name, as: result)

		// Define the node
		context.define(syntax, as: result)

		return result
	}

	func visit(_ syntax: EnumCaseDeclSyntax, _ context: Context) throws -> InferenceResult {
		guard let enumType = context.lexicalScope as? Enum else {
			throw TypeError.typeError("Did not get enum for case \(syntax.description)")
		}

		let name = syntax.nameToken.lexeme

		enumType.cases[name] = try Enum.Case(
			type: enumType,
			name: name,
			module: context.module,
			attachedTypes: syntax.attachedTypes.map { try $0.accept(self, context) }
		)

		return .resolved(.void)
	}

	func visit(_ syntax: MatchStatementSyntax, _ context: Context) throws -> InferenceResult {
		let target = try syntax.target.accept(self, context)

		try context.expecting(target) {
			for kase in syntax.cases {
				let result = try kase.accept(self, context)
				context.define(kase, as: result)
			}
		}

		return .resolved(.void)
	}

	func visit(_ syntax: CaseStmtSyntax, _ context: Context) throws -> InferenceResult {
		let childContext = context.addChild(lexicalScope: context.lexicalScope)

		guard let expectedType = context.expectedType else {
			throw TypeError.typeError("Expected type for case \(syntax.description)")
		}

		try childContext.expecting(expectedType) {
			if let patternSyntax = syntax.patternSyntax {
				let patternVisitor = PatternVisitor(visitor: self)
				let pattern = try patternSyntax.accept(patternVisitor, childContext)
				context.define(patternSyntax, as: .resolved(.pattern(pattern)))
			}
		}

		for stmt in syntax.body {
			_ = try stmt.accept(self, childContext)
		}

		context.define(syntax, as: .resolved(.void))
		return .resolved(.void)
	}

	func visit(_ syntax: EnumMemberExprSyntax, _ context: Context) throws -> InferenceResult {
		fatalError("WIP")
	}

	func visit(_ syntax: InterpolatedStringExprSyntax, _ context: Context) throws -> InferenceResult {
		.resolved(.base(.string))
	}

	func visit(_ syntax: ForStmtSyntax, _ context: Context) throws -> InferenceResult {
		let childContext = context.addChild()

		// Visit the sequence so we can get its type
		let sequenceType = try syntax.sequence.accept(self, childContext)

		// See if we can get substitutions
		let substitutions: Substitutions = if case let .resolved(.instance(instance)) = sequenceType {
			instance.substitutions
		} else {
			[:]
		}

		// Get the builtin iterable protocol
		let iterable = try context.builtin(named: "Iterable").asInstance(in: childContext, with: substitutions)
		guard case let .instance(.protocol(iterableInstance)) = iterable else {
			context.error("Could not instantiate iterablw", at: syntax.sequence.location)
			return .resolved(.void)
		}

		guard let expectedElementType = iterableInstance.relatedType(named: "Element") else {
			context.error("Unable to determine expected element type of \(syntax.element.description)", at: syntax.element.location)
			return .resolved(.void)
		}

		context.addConstraint(
			Constraints.Conformance(
				context: childContext,
				type: sequenceType,
				conformsTo: .resolved(iterable),
				location: syntax.sequence.location
			)
		)

		let patternVisitor = PatternVisitor(visitor: self)
		let pattern = try childContext.expecting(.resolved(expectedElementType)) {
			try syntax.element.accept(patternVisitor, childContext)
		}

		if case let .variable(name, type) = pattern {
			childContext.define(name, as: type)
		}

		context.addConstraint(
			Constraints.Bind(context: childContext, target: .resolved(expectedElementType), pattern: pattern, location: syntax.element.location)
		)

		_ = try syntax.body.accept(self, childContext)

		context.define(syntax, as: .resolved(.void))
		return .resolved(.void)
	}

	func visit(_ syntax: LogicalExprSyntax, _ context: Context) throws -> InferenceResult {
		let lhs = try syntax.lhs.accept(self, context)
		let rhs = try syntax.rhs.accept(self, context)

		context.addConstraint(Constraints.Equality(context: context, lhs: lhs, rhs: rhs, location: syntax.location))

		context.define(syntax, as: .resolved(.base(.bool)))
		return .resolved(.base(.bool))
	}

	func visit(_ syntax: GroupedExprSyntax, _ context: Context) throws -> InferenceResult {
		let result = try syntax.expr.accept(self, context)
		context.define(syntax, as: result)
		return result
	}

	func visit(_ syntax: LetPatternSyntax, _ context: Context) throws -> InferenceResult {
		if let value = try syntax.value?.accept(self, context) {
			context.define(syntax.name.lexeme, as: value)
		} else {
			if let variable = context.type(named: syntax.name.lexeme) {
				context.define(syntax.name.lexeme, as: unwrapped(variable, in: context, location: syntax.location))
			} else {
				context.error("Undefined variable: \(syntax.name.lexeme)", at: syntax.location)
			}
		}

		return .resolved(.void)
	}

	func visit(_ syntax: MethodDeclSyntax, _ context: Context) throws -> InferenceResult {
		guard let lexicalScope = context.lexicalScope else {
			context.error("Could not find lexical scope for method: `\(syntax.nameToken.lexeme)`", at: syntax.location)
			return .resolved(.any)
		}

		let result = try handleFuncLike(syntax, context: context)
		let name = syntax.nameToken.lexeme
		try lexicalScope.add(member: result, named: name, isStatic: syntax.isStatic)

		return .resolved(.void)
	}

	func visit(_ syntax: PropertyDeclSyntax, _ context: Context) throws -> InferenceResult {
		guard let lexicalScope = context.lexicalScope else {
			context.error("Could not find lexical scope for property: `\(syntax.name)`", at: syntax.location)
			return .resolved(.any)
		}

		let name = syntax.name.lexeme
		let annotatedType: InferenceResult? = try syntax.typeAnnotation.flatMap {
			// Get the type of the property, this needs to be recursive.
			let type = try visit($0, context)

			var subsitutions: Substitutions = [:]

			if case let .scheme(scheme) = type {
				for (schemeVariable, paramSyntax) in zip(scheme.variables, $0.genericParams) {
					let typeArgument = try visit(paramSyntax, context)
					subsitutions[schemeVariable] = typeArgument.instantiate(in: context).type
				}
			} else if case let .resolved(.type(type)) = type {
				for ((_, typeVar), paramSyntax) in zip(type.typeParameters, $0.genericParams) {
					let typeArgument = try visit(paramSyntax, context)

					context.addConstraint(
						Constraints.Equality(context: context, lhs: .resolved(.typeVar(typeVar)), rhs: typeArgument, location: paramSyntax.location)
					)

					subsitutions[typeVar] = typeArgument.asInstance(in: context, with: subsitutions)
				}
			}

			// If it's an instance, we want to make the member be an instance
			var result = type.instantiate(in: context, with: subsitutions).type
			if case let .type(.struct(type)) = result {
				result = .instance(.struct(type.instantiate(with: subsitutions)))
			}

			return .resolved(result)
		}

		let valueType = try syntax.defaultValue.flatMap {
			try $0.accept(self, context)
		}

		if let annotatedType, let valueType {
			// If we've got both an annotated type and a default value, make sure they match
			context.addConstraint(Constraints.Equality(context: context, lhs: annotatedType, rhs: valueType, location: syntax.location))
		}

		let result = annotatedType ?? valueType ?? .resolved(.typeVar(context.freshTypeVariable("\(lexicalScope.name).\(syntax.name)")))
		try lexicalScope.add(member: result, named: name, isStatic: syntax.isStatic)

		return .resolved(.void)
	}
}
