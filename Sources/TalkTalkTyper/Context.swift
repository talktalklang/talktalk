//
//  Context.swift
//
//
//  Created by Pat Nakajima on 7/13/24.
//
import TalkTalkSyntax

class ReturnTracker {
	var depth: Int
	var returns: [any Expr] = []

	init(depth: Int, returns: [any Expr] = []) {
		self.depth = depth
		self.returns = returns
	}

	func add(_ stmt: any Expr) {
		returns.append(stmt)
	}

	func type(in context: Context) -> ValueType? {
		if let ret = returns.last {
			return TyperVisitor(ast: ret).visit(ret, context: context)?.type
		}

		return nil
	}
}

class Context {
	enum Error: Swift.Error {
		case notInClass
	}

	var returns: [ReturnTracker] = []
	var environments: [CaptureEnvironment] = [CaptureEnvironment()]
	var scopes: [VariableScope] = [VariableScope()]
	var classes: [
		[String: Property]
	] = []

	init(scopes: [VariableScope] = [VariableScope()]) {
		self.scopes = scopes
	}

	var currentScope: VariableScope {
		scopes.last!
	}

	func needsCapture(for node: any Syntax) -> Bool {
		if currentScope.lookup(identifier: name(for: node)) != nil {
			return false
		}

		var parent = currentScope
		while let nextParent = parent.parent {
			if nextParent.lookup(identifier: name(for: node)) != nil {
				return true
			}

			parent = nextParent
		}

		return false
	}

	func capture(_ node: any Syntax) -> TypedValue {
		var typedValue = lookup(node, withParents: true)!
		typedValue.isEscaping = true
		currentEnvironment.capture(value: typedValue, as: name(for: node))
		return typedValue
	}

	// TODO: Handle depth issues
	func withScope<T>(perform: (Context) -> T) -> T {
		let scope = VariableScope(parent: currentScope)
		scopes.append(scope)
		return perform(self)
	}

	func withClassScope(perform: (Context) -> Void) -> [String: Property] {
		classes.append([:])
		defer {
			_ = self.classes.popLast()
		}

		perform(self)
		return currentClass!
	}

	var currentClass: [String: Property]? {
		get {
			classes.last
		}

		set {
			classes[classes.count - 1] = newValue!
		}
	}

	func lookup(_ syntax: any Syntax, withParents: Bool = false) -> TypedValue? {
		currentScope.lookup(identifier: name(for: syntax), withParents: withParents)
	}

	func lookup(type: String) -> ValueType? {
		currentScope.lookup(type: type)
	}

	func lookup(identifier: String) -> TypedValue? {
		currentScope.lookup(identifier: identifier)
	}

	func define(_ syntax: any Syntax, as typedef: TypedValue) {
		currentScope.locals[name(for: syntax)] = typedef
	}

	func define(_ syntax: any Syntax, as type: ValueType, status: TypedValue.Status) {
		currentScope.locals[name(for: syntax)] = TypedValue(
			type: type,
			definition: syntax,
			status: status
		)
	}

	func define(type: ValueType) {
		currentScope.types[type.name] = type
	}

	func define(member: String, as type: TypedValue, at token: any Syntax) throws {
		guard currentClass != nil else {
			throw Error.notInClass
		}

		currentClass![member] = .init(
			name: member,
			type: type,
			definition: token
		)
	}

	func withEnvironment<T>(perform: (CaptureEnvironment) -> T) -> T {
		let newEnvironment = CaptureEnvironment(parent: currentEnvironment)
		environments.append(newEnvironment)

		defer {
			_ = environments.popLast()
		}

		return perform(newEnvironment)
	}

	func withReturnTracking(perform: (Context) -> Void) -> ReturnTracker {
		let returns = ReturnTracker(depth: returns.count)
		self.returns.append(returns)
		perform(self)
		return self.returns.popLast()!
	}

	func infer(from type: ValueType, to destination: TypedValue) -> TypedValue? {
		guard destination.type == .tbd else {
			return nil
		}

		let newValue = TypedValue(
			type: type,
			definition: destination.definition,
			status: .defined
		)

		define(destination.definition, as: newValue)

		return newValue
	}

	var currentEnvironment: CaptureEnvironment {
		environments.last!
	}

	func name(for syntax: any Syntax) -> String {
		switch syntax {
		case let syntax as VariableExprSyntax:
			syntax.name.lexeme
		case let syntax as IdentifierSyntax:
			syntax.lexeme
		case let syntax as FunctionDeclSyntax:
			syntax.name.lexeme
		case let syntax as IntLiteralSyntax:
			syntax.lexeme
		case let syntax as VarDeclSyntax:
			syntax.variable.lexeme
		case let syntax as LetDeclSyntax:
			syntax.variable.lexeme
		default:

			"NO NAME FOR \(syntax)"
		}
	}
}
