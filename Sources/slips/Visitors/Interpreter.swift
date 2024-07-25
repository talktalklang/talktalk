//
//  Interpreter.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Interpreter: Visitor {
	let exprs: [any Expr]

	public init(_ code: String) {
		let lexer = Lexer(code)
		var parser = Parser(lexer)

		if !parser.errors.isEmpty {
			fatalError(parser.errors.description)
		}

		self.exprs = parser.parse()
		if !parser.errors.isEmpty {
			for (_, message) in parser.errors {
				print(message)
			}
		}
	}

	public func evaluate() -> Value {
		var last: Value = .none
		let rootScope = Scope()

		for expr in exprs {
			last = expr.accept(self, rootScope)
		}
		return last
	}

	public func visit(_ expr: AddExpr, _ scope: Scope) -> Value {
		let operands = expr.operands

		if operands.count == 0 {
			return .none
		}

		var result: Value = operands[0].accept(self, scope)

		for next in operands[1 ..< operands.count] {
			result = result.add(next.accept(self, scope))
		}

		return result
	}

	public func visit(_ expr: CallExpr, _ scope: Scope) -> Value {
		if case let .fn(fn) = scope.lookup(expr.op.lexeme) {
			let innerScope = Scope(parent: scope)

			for (i, argument) in expr.args.enumerated() {
				_ = innerScope.define(fn.params.names[i], argument.accept(self, innerScope))
			}

			var lastReturn: Value = .none
			for expr in fn.body {
				lastReturn = expr.accept(self, innerScope)
			}

			return lastReturn
		} else {
			fatalError("\(expr.op.lexeme) not callable")
		}
	}

	public func visit(_ expr: DefExpr, _ scope: Scope) -> Value {
		scope.define(expr.name.lexeme, expr.expr.accept(self, scope))
	}

	public func visit(_: ErrorExpr, _: Scope) -> Value {
		.none
	}

	public func visit(_ expr: LiteralExpr, _: Scope) -> Value {
		expr.value
	}

	public func visit(_ expr: VarExpr, _ scope: Scope) -> Value {
		scope.locals[expr.name] ?? .none
	}

	public func visit(_ expr: IfExpr, _ scope: Scope) -> Value {
		let condition = expr.condition.accept(self, scope)

		return if condition.isTruthy {
			expr.consequence.accept(self, scope)
		} else {
			expr.alternative.accept(self, scope)
		}
	}

	public func visit(_ expr: FuncExpr, _: Scope) -> Value {
		.fn(expr)
	}

	public func visit(_: ParamsExpr, _: Scope) -> Value {
		.bool(false)
	}

	private

	func runtimeError(_ err: String) {
		fatalError(err)
	}
}
