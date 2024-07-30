//
//  Interpreter.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct Interpreter: Visitor {
	let exprs: [any Expr]

	public init(_ code: String) {
		let lexer = TalkTalkLexer(code)
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
		let rootScope = Scope()

		for expr in exprs {
			last = expr.accept(self, rootScope)
		}

		return last
	}

	public func visit(_ expr: any BinaryExpr, _ scope: Scope) -> Value {
		let lhs = expr.lhs.accept(self, scope)
		let rhs = expr.rhs.accept(self, scope)

		let result: Value =
			switch expr.op {
			case .plus:
				lhs.add(rhs)
			case .equalEqual:
				.bool(lhs == rhs)
			case .bangEqual:
				.bool(lhs != rhs)
			}

		return result
	}

	public func visit(_ expr: CallExpr, _ scope: Scope) -> Value {
		let callee = expr.callee.accept(self, scope)

		if case let .fn(closure) = callee {
			return call(closure, args: expr.args.map(\.value), scope)
		} else {
			fatalError("\(expr.callee.description) not callable")
		}
	}

	public func visit(_ expr: DefExpr, _ scope: Scope) -> Value {
		scope.define(expr.name.lexeme, expr.value.accept(self, scope))
	}

	public func visit(_ expr: LiteralExpr, _: Scope) -> Value {
		switch expr.value {
		case let .bool(bool):
			return .bool(bool)
		case let .int(int):
			return .int(int)
		case .none:
			return .none
		}
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

		if let name = expr.name {
			_ = scope.define(name, .fn(Closure(funcExpr: expr, environment: childScope)))
		}

		return .fn(Closure(funcExpr: expr, environment: childScope))
	}

	public func visit(_: ParamsExpr, _: Scope) -> Value {
		fatalError("unreachable")
	}

	public func visit(_ expr: any Param, _ context: Scope) -> Value {
		context.lookup(expr.name)
	}

	public func visit(_ expr: any WhileExpr, _ context: Scope) -> Value {
		var lastResult: Value = .none
		while expr.condition.accept(self, context) == .bool(true) {
			lastResult = visit(expr.body, context)
		}
		return lastResult
	}

	public func visit(_ expr: any BlockExpr, _ context: Scope) -> Value {
		lastResult(of: expr.exprs, in: context)
	}

	public func visit(_ expr: any ErrorSyntax, _ context: Scope) -> Value {
		fatalError(expr.message)
	}

	public func visit(_ expr: any StructExpr, _ context: Scope) -> Value {
		fatalError()
	}

	public func visit(_ expr: any DeclBlockExpr, _ context: Scope) -> Value {
		fatalError()
	}

	public func visit(_ expr: any VarDecl, _ context: Scope) -> Value {
		fatalError()
	}

	private func lastResult(of exprs: [any Expr], in context: Scope) -> Value {
		var lastResult: Value = .none
		for expr in exprs {
			lastResult = expr.accept(self, context)
		}
		return lastResult
	}

	func call(_ closure: Closure, args: [any Expr], _ scope: Scope) -> Value {
		for (i, argument) in args.enumerated() {
			_ = scope.define(
				closure.funcExpr.params.params[i].name,
				argument.accept(self, scope)
			)
		}

		var lastReturn: Value = .none

		for expr in closure.funcExpr.body.exprs {
			lastReturn = expr.accept(self, scope)
		}

		return lastReturn
	}

	func runtimeError(_ err: String) {
		fatalError(err)
	}
}
