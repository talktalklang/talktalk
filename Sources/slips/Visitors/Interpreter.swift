//
//  Interpreter.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct Interpreter: Visitor {
	let exprs: [any Expr]

	public init(_ code: String) {
		let lexer = SlipsLexer(code)
		var parser = SlipsParser(lexer)
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
		let operands = [expr.lhs, expr.rhs]

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
		let callee = expr.callee.accept(self, scope)

		if case let .fn(closure) = callee {
			return call(closure, args: expr.args, scope)
		} else {
			fatalError("\(expr.callee.description) not callable")
		}
	}

	public func visit(_ expr: DefExpr, _ scope: Scope) -> Value {
		scope.define(expr.name.lexeme, expr.value.accept(self, scope))
	}

	public func visit(_ err: ErrorExpr, _: Scope) -> Value {
		print(err.message)
		return .none
	}

	public func visit(_ expr: LiteralExpr, _: Scope) -> Value {
		expr.value
	}

	public func visit(_ expr: VarExpr, _ scope: Scope) -> Value {
		scope.lookup(expr.name)
	}

	public func visit(_ expr: IfExpr, _ scope: Scope) -> Value {
		let condition = expr.condition.accept(self, scope)

		return if condition.isTruthy {
			expr.consequence.accept(self, scope)
		} else {
			expr.alternative.accept(self, scope)
		}
	}

	public func visit(_ expr: FuncExpr, _ scope: Scope) -> Value {
		let childScope = Scope(parent: scope)
		return .fn(Closure(funcExpr: expr, environment: childScope))
	}

	public func visit(_: ParamsExpr, _: Scope) -> Value {
		.bool(false)
	}

	public func visit(_ expr: any Param, _ context: Scope) -> Value {
		context.lookup(expr.name)
	}

	private

	func call(_ closure: Closure, args: [any Expr], _ scope: Scope) -> Value {
		for (i, argument) in args.enumerated() {
			_ = scope.define(closure.funcExpr.params.params[i].name, argument.accept(self, scope))
		}

		var lastReturn: Value = .none

		for expr in closure.funcExpr.body {
			lastReturn = expr.accept(self, scope)
		}

		return lastReturn
	}

	func runtimeError(_ err: String) {
		fatalError(err)
	}
}
