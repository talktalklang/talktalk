//
//  Context.swift
//
//
//  Created by Pat Nakajima on 7/13/24.
//
import TalkTalkSyntax

class Context {
	enum Error: Swift.Error {
		case notInClass
	}

	var scopes: [Scope] = [Scope()]
	var classes: [
		[String: Property]
	] = []

	init(scopes: [Scope] = [Scope()]) {
		self.scopes = scopes
	}

	var currentScope: Scope {
		scopes.last!
	}

	// TODO: Handle depth issues
	func withScope<T>(perform: (Context) -> T) -> T {
		let scope = Scope(parent: currentScope)
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

	func lookup(_ syntax: any Syntax) -> TypedValue? {
		currentScope.lookup(identifier: name(for: syntax))
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
		currentScope.locals[name(for: syntax)] = TypedValue(type: type, definition: syntax, status: status)
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
