//
//  Interpreter.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkAnalysis
import TalkTalkSyntax

public struct InterpreterStruct {
	var name: String
	var properties: [String: Value]
}

public struct Interpreter: AnalyzedVisitor {
	let main: AnalyzedFuncExpr

	public init(_ code: String) {
		let lexer = TalkTalkLexer(code)
		var parser = Parser(lexer)
		let parsed = parser.parse()

		self.main = Analyzer.analyze(parsed).cast(AnalyzedFuncExpr.self)

		if !parser.errors.isEmpty {
			for (_, message) in parser.errors {
				print(message)
			}
		}
	}

	public func evaluate() -> Value {
		var last: Value = .none
		let rootScope = Scope()

		for expr in main.bodyAnalyzed.exprsAnalyzed {
			last = expr.accept(self, rootScope)
		}

		return last
	}

	public func visit(_ expr: AnalyzedMemberExpr, _ context: Scope) -> Value {
		guard case let .instance(instance) = expr.receiverAnalyzed.accept(self, context) else {
			fatalError("not an instance")
		}

		guard let value = instance.resolve(property: expr.property) else {
			fatalError("\(instance) has no property: \(expr.property)")
		}

		return value
	}

	public func visit(_ expr: AnalyzedBinaryExpr, _ scope: Scope) -> Value {
		let lhs = expr.lhsAnalyzed.accept(self, scope)
		let rhs = expr.rhsAnalyzed.accept(self, scope)

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

	public func visit(_ expr: AnalyzedCallExpr, _ scope: Scope) -> Value {
		let callee = expr.calleeAnalyzed.accept(self, scope)

		if case let .fn(closure) = callee {
			return call(closure, args: expr.argsAnalyzed.map(\.expr), scope)
		} else if case let .method(funcExpr, instance) = callee {
			return call(funcExpr, on: instance, with: expr.argsAnalyzed.map(\.expr))
		} else if case let .struct(type) = callee {
			return instantiate(type, with: expr.argsAnalyzed, in: scope)
		} else {
			fatalError("\(callee) not callable")
		}
	}

	public func visit(_ expr: AnalyzedDefExpr, _ scope: Scope) -> Value {
		scope.define(expr.name.lexeme, expr.valueAnalyzed.accept(self, scope))
	}

	public func visit(_ expr: AnalyzedLiteralExpr, _: Scope) -> Value {
		switch expr.value {
		case let .bool(bool):
			return .bool(bool)
		case let .int(int):
			return .int(int)
		case .none:
			return .none
		}
	}

	public func visit(_ expr: AnalyzedVarExpr, _ scope: Scope) -> Value {
		scope.lookup(expr.name)
	}

	public func visit(_ expr: AnalyzedIfExpr, _ scope: Scope) -> Value {
		let condition = expr.conditionAnalyzed.accept(self, scope)

		return if condition.isTruthy {
			expr.consequenceAnalyzed.accept(self, scope)
		} else {
			expr.alternativeAnalyzed.accept(self, scope)
		}
	}

	public func visit(_ expr: AnalyzedFuncExpr, _ scope: Scope) -> Value {
		let childScope = Scope(parent: scope)

		if let name = expr.name {
			_ = scope.define(name, .fn(Closure(funcExpr: expr, environment: childScope)))
		}

		return .fn(Closure(funcExpr: expr, environment: childScope))
	}

	public func visit(_: AnalyzedParamsExpr, _: Scope) -> Value {
		fatalError("unreachable")
	}

	public func visit(_ expr: any Param, _ context: Scope) -> Value {
		context.lookup(expr.name)
	}

	public func visit(_ expr: AnalyzedWhileExpr, _ context: Scope) -> Value {
		var lastResult: Value = .none
		while expr.conditionAnalyzed.accept(self, context) == .bool(true) {
			lastResult = visit(expr.bodyAnalyzed, context)
		}
		return lastResult
	}

	public func visit(_ expr: AnalyzedBlockExpr, _ context: Scope) -> Value {
		lastResult(of: expr.exprsAnalyzed, in: context)
	}

	public func visit(_ expr: AnalyzedErrorSyntax, _ context: Scope) -> Value {
		fatalError(expr.message)
	}

	public func visit(_ expr: AnalyzedStructExpr, _ context: Scope) -> Value {
		var type = StructType(
			name: expr.name,
			properties: [:],
			methods: [:]
		)

		for decl in expr.bodyAnalyzed.declsAnalyzed {
			if let funcExpr = decl as? AnalyzedFuncExpr {
				type.methods[funcExpr.name!] = funcExpr
			}
		}

		let retVal: Value = .struct(type)

		if let name = expr.name {
			_ = context.define(name, retVal)
		}

		return retVal
	}

	public func visit(_ expr: AnalyzedDeclBlock, _ context: Scope) -> Value {
		.none
	}

	public func visit(_ expr: AnalyzedVarDecl, _ context: Scope) -> Value {
		fatalError()
	}

	public func visit(_ expr: AnalyzedLetDecl, _ context: Scope) -> Value {
		fatalError()
	}

	private func lastResult(of exprs: [any AnalyzedExpr], in context: Scope) -> Value {
		var lastResult: Value = .none
		for expr in exprs {
			lastResult = expr.accept(self, context)
		}
		return lastResult
	}

	func call(_ funcExpr: AnalyzedFuncExpr, on instance: StructInstance, with args: [any AnalyzedExpr]) -> Value {
		let scope = Scope()
		_ = scope.define("self", .instance(instance))

		for (i, argument) in args.enumerated() {
			_ = scope.define(
				funcExpr.params.params[i].name,
				argument.accept(self, scope)
			)
		}

		var lastReturn: Value = .none

		for expr in funcExpr.bodyAnalyzed.exprsAnalyzed {
			lastReturn = expr.accept(self, scope)
		}

		return lastReturn
	}

	func call(_ closure: Closure, args: [any AnalyzedExpr], _ scope: Scope) -> Value {
		for (i, argument) in args.enumerated() {
			_ = scope.define(
				closure.funcExpr.params.params[i].name,
				argument.accept(self, scope)
			)
		}

		var lastReturn: Value = .none

		for expr in closure.funcExpr.bodyAnalyzed.exprsAnalyzed {
			lastReturn = expr.accept(self, scope)
		}

		return lastReturn
	}

	func instantiate(_ type: StructType, with args: [AnalyzedArgument], in context: Scope) -> Value {
		var instance = StructInstance(type: type, properties: [:])

		for arg in args {
			guard let label = arg.label else {
				fatalError("expected argument label when instantiating \(type)")
			}

			instance.properties[label] = arg.expr.accept(self, context)
		}

		return .instance(instance)
	}

	func runtimeError(_ err: String) {
		fatalError(err)
	}
}
