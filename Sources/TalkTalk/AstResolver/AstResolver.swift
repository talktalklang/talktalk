//
//  AstResolver.swift
//
//
//  Created by Pat Nakajima on 6/29/24.
//
struct Scope {
	struct Status: OptionSet {
		let rawValue: Int
		static let declared = Status(rawValue: 1 << 0)
		static let defined = Status(rawValue: 1 << 1)
	}

	var storage: [String: Status] = [:]

	func get(_ name: String) -> Scope.Status? {
		storage[name]
	}

	func contains(_ token: Token) -> Bool {
		storage.index(forKey: token.lexeme) != nil
	}

	mutating func mark(_ token: Token, as status: Scope.Status) {
		storage[token.lexeme, default: Status()].insert(status)
	}

	mutating func mark(_ name: String, as status: Scope.Status)  {
		storage[name, default: Status()].insert(status)
	}
}

struct AstResolver {
	enum FunctionType {
		case none, function, method
	}

	var interpreter: AstInterpreter
	var scopes: [Scope] = []
	var currentFunction: FunctionType = .none

	mutating func beginScope() {
		scopes.append(Scope())
	}

	mutating func endScope() {
		_ = scopes.popLast()
	}

	mutating func declare(_ token: Token) {
		if scopes.isEmpty { return }
		scopes[scopes.count - 1].mark(token, as: .declared)
	}

	mutating func define(_ token: Token) {
		if scopes.isEmpty { return }
		scopes[scopes.count - 1].mark(token, as: .defined)
	}

	mutating func resolveLocal(expr: any Expr, name: Token) {
		var i = scopes.count - 1
		while i >= 0 {
			if scopes[i].contains(name) {
				interpreter.resolve(expr, depth: scopes.count - 1 - i)
				return
			}

			i -= 1
		}
	}

	mutating func resolveFunction(_ function: FunctionStmt, _ type: FunctionType) throws {
		let enclosingFunctionType = currentFunction
		currentFunction = type

		beginScope()

		for param in function.params {
			declare(param)
			define(param)
		}

		try resolve(function.body)

		endScope()
		currentFunction = enclosingFunctionType
	}

	mutating func resolve(_ statement: any Stmt) throws {
		try statement.accept(visitor: &self)
	}

	@discardableResult mutating func resolve(_ statements: [any Stmt]) throws -> AstInterpreter {
		for statement in statements {
			try resolve(statement)
		}

		return interpreter
	}

	mutating func resolve(_ expression: any Expr) throws {
		try expression.accept(visitor: &self)
	}

	mutating func resolve(_ expressions: [any Expr]) throws {
		for expression in expressions {
			try resolve(expression)
		}
	}
}
