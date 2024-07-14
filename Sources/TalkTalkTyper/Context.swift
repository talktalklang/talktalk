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

	func define(_ syntax: any Syntax, as typedef: TypedValue) {
		currentScope.locals[name(for: syntax)] = typedef
	}

	func define(_ syntax: any Syntax, as type: ValueType) {
		currentScope.locals[name(for: syntax)] = TypedValue(type: type, definition: syntax)
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

	func name(for syntax: any Syntax) -> String {
		switch syntax {
		case let syntax as VariableExprSyntax:
			syntax.name.lexeme
		case let syntax as IdentifierSyntax:
			syntax.lexeme
		case let syntax as FunctionDeclSyntax:
			syntax.name.lexeme
		default:

			"NO NAME FOR \(syntax)"
		}
	}
}
