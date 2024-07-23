//
//  Interpreter.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Interpreter: Visitor {
	let exprs: [any Expr]
	var scopes: [Scope] = [Scope()]

	public init(_ code: String) {
		let lexer = Lexer(code)
		var parser = Parser(lexer)
		self.exprs = parser.parse()
		if !parser.errors.isEmpty {
			for (_, message) in parser.errors {
				print(message)
			}
		}
	}

	public func evaluate() -> Value {
		var last: Value = .none
		for expr in exprs {
			last = expr.accept(self)
		}
		return last
	}

	public func visit(_ expr: AddExpr) -> Value {
		let operands = expr.operands

		if operands.count == 0 {
			return .none
		}

		var result: Value = operands[0].accept(self)

		for next in operands[1 ..< operands.count] {
			result = result.add(next.accept(self))
		}

		return result
	}

	public func visit(_: CallExpr) -> Value {
		.none
	}

	public func visit(_ expr: DefExpr) -> Value {
		currentScope.define(expr.name.lexeme, expr.expr.accept(self))
	}

	public func visit(_: ErrorExpr) -> Value {
		.none
	}

	public func visit(_ expr: LiteralExpr) -> Value {
		expr.value
	}

	public func visit(_ expr: VarExpr) -> Value {
		currentScope.locals[expr.name] ?? .none
	}

	public func visit(_ expr: IfExpr) -> Value {
		let condition = expr.condition.accept(self)

		return if condition.isTruthy {
			expr.consequence.accept(self)
		} else {
			expr.alternative.accept(self)
		}
	}

	var currentScope: Scope {
		get {
			scopes.last!
		}

		set {
			scopes[scopes.count - 1] = newValue
		}
	}
}
