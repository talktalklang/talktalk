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
	enum Return: Error, @unchecked Sendable {
		case returning(Value)
	}

	let main: AnalyzedFuncExpr

	public init(_ code: String) {
		let lexer = TalkTalkLexer(code)
		var parser = Parser(lexer)
		let parsed = parser.parse()

		self.main = try! Analyzer.analyze(parsed).cast(AnalyzedFuncExpr.self)

		if !parser.errors.isEmpty {
			for (_, message) in parser.errors {
				print(message)
			}
		}
	}

	public func evaluate() throws -> Value {
		var last: Value = .none
		let rootScope = Scope()

		for expr in main.bodyAnalyzed.exprsAnalyzed {
			last = try expr.accept(self, rootScope)
		}

		return last
	}

	public func visit(_ expr: AnalyzedIdentifierExpr, _ context: Scope) throws -> Value {
		.none
	}

	public func visit(_ expr: AnalyzedUnaryExpr, _ context: Scope) throws -> Value {
		switch expr.op {
		case .bang:
			try expr.exprAnalyzed.accept(self, context).negate()
		case .minus:
			try expr.exprAnalyzed.accept(self, context).negate()
		default:
			fatalError("unreachable")
		}
	}

	public func visit(_ expr: AnalyzedMemberExpr, _ context: Scope) throws -> Value {
		guard case let .instance(instance) = try expr.receiverAnalyzed.accept(self, context) else {
			fatalError("not an instance")
		}

		guard let value = instance.resolve(property: expr.property) else {
			fatalError("\(instance) has no property: \(expr.property)")
		}

		return value
	}

	public func visit(_ expr: AnalyzedBinaryExpr, _ scope: Scope) throws -> Value {
		let lhs = try expr.lhsAnalyzed.accept(self, scope)
		let rhs = try expr.rhsAnalyzed.accept(self, scope)

		let result: Value =
			switch expr.op {
			case .plus:
				lhs.add(rhs)
			case .equalEqual:
				.bool(lhs == rhs)
			case .bangEqual:
				.bool(lhs != rhs)
			case .less:
				.bool(lhs < rhs)
			case .lessEqual:
				.bool(lhs <= rhs)
			case .greater:
				.bool(lhs > rhs)
			case .greaterEqual:
				.bool(lhs >= rhs)
			case .minus:
				lhs.minus(rhs)
			case .star:
				lhs.times(rhs)
			case .slash:
				lhs.div(rhs)
			}

		return result
	}

	public func visit(_ expr: AnalyzedCallExpr, _ scope: Scope) throws -> Value {
		let callee = try expr.calleeAnalyzed.accept(self, scope)

		if case let .fn(closure) = callee {
			let val = try call(closure, args: expr.argsAnalyzed.map(\.expr), scope)
			return val
		} else if case let .method(funcExpr, instance) = callee {
			return try call(funcExpr, on: instance, with: expr.argsAnalyzed.map(\.expr))
		} else if case let .struct(type) = callee {
			return try instantiate(type, with: expr.argsAnalyzed, in: scope)
		} else if case .builtin(_) = callee {
			_ = try expr.argsAnalyzed.map { try $0.expr.accept(self, scope) }
			return .none
		} else {
			fatalError("\(callee) not callable")
		}
	}

	public func visit(_ expr: AnalyzedDefExpr, _ scope: Scope) throws -> Value {
		try scope.define(expr.name.lexeme, expr.valueAnalyzed.accept(self, scope))
	}

	public func visit(_ expr: AnalyzedLiteralExpr, _: Scope) throws -> Value {
		switch expr.value {
		case let .bool(bool):
			return .bool(bool)
		case let .int(int):
			return .int(int)
		case let .string(string):
			return .string(string)
		case .none:
			return .none
		}
	}

	public func visit(_ expr: AnalyzedVarExpr, _ scope: Scope) throws -> Value {
		scope.lookup(expr.name)
	}

	public func visit(_ expr: AnalyzedIfExpr, _ scope: Scope) throws -> Value {
		let condition = try expr.conditionAnalyzed.accept(self, scope)

		if condition.isTruthy {
			let val = try expr.consequenceAnalyzed.accept(self, scope)
			return val
		} else {
			return try expr.alternativeAnalyzed.accept(self, scope)
		}
	}

	public func visit(_ expr: AnalyzedFuncExpr, _ scope: Scope) throws -> Value {
		let childScope = Scope(parent: scope)

		if let name = expr.name {
			_ = scope.define(name, .fn(Closure(funcExpr: expr, environment: childScope)))
		}

		return .fn(Closure(funcExpr: expr, environment: childScope))
	}

	public func visit(_: AnalyzedParamsExpr, _: Scope) throws -> Value {
		fatalError("unreachable")
	}

	public func visit(_ expr: any Param, _ context: Scope) throws -> Value {
		context.lookup(expr.name)
	}

	public func visit(_ expr: AnalyzedWhileExpr, _ context: Scope) throws -> Value {
		var lastResult: Value = .none
		while try expr.conditionAnalyzed.accept(self, context) == .bool(true) {
			lastResult = try visit(expr.bodyAnalyzed, context)
		}
		return lastResult
	}

	public func visit(_ expr: AnalyzedBlockExpr, _ context: Scope) throws -> Value {
		try lastResult(of: expr.exprsAnalyzed, in: context)
	}

	public func visit(_ expr: AnalyzedErrorSyntax, _ context: Scope) throws -> Value {
		fatalError(expr.message)
	}

	public func visit(_ expr: AnalyzedStructExpr, _ context: Scope) throws -> Value {
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

	public func visit(_ expr: AnalyzedReturnExpr, _ context: Scope) throws -> Value {
		let value = try expr.valueAnalyzed?.accept(self, context)
		throw Return.returning(value ?? .none)
	}

	public func visit(_ expr: AnalyzedDeclBlock, _ context: Scope) throws -> Value {
		.none
	}

	public func visit(_ expr: AnalyzedVarDecl, _ context: Scope) throws -> Value {
		fatalError()
	}

	public func visit(_ expr: AnalyzedLetDecl, _ context: Scope) throws -> Value {
		fatalError()
	}

	private func lastResult(of exprs: [any AnalyzedExpr], in context: Scope) throws -> Value {
		var lastResult: Value = .none
		for expr in exprs {
			lastResult = try expr.accept(self, context)
		}
		return lastResult
	}

	func call(_ funcExpr: AnalyzedFuncExpr, on instance: StructInstance, with args: [any AnalyzedExpr]) throws -> Value {
		let scope = Scope()
		_ = scope.define("self", .instance(instance))

		for (i, argument) in args.enumerated() {
			_ = scope.define(
				funcExpr.params.params[i].name,
				try argument.accept(self, scope)
			)
		}

		var lastReturn: Value = .none

		for expr in funcExpr.bodyAnalyzed.exprsAnalyzed {
			do {
				lastReturn = try expr.accept(self, scope)
			} catch let Return.returning(value) {
				return value
			}
		}

		return lastReturn
	}

	func call(_ closure: Closure, args: [any AnalyzedExpr], _ scope: Scope) throws -> Value {
		for (i, argument) in args.enumerated() {
			_ = scope.define(
				closure.funcExpr.params.params[i].name,
				try argument.accept(self, scope)
			)
		}

		var lastReturn: Value = .none

		for expr in closure.funcExpr.bodyAnalyzed.exprsAnalyzed {
			do {
				lastReturn = try expr.accept(self, scope)
			} catch let Return.returning(value) {
				return value
			}
		}

		return lastReturn
	}

	func instantiate(_ type: StructType, with args: [AnalyzedArgument], in context: Scope) throws -> Value {
		var instance = StructInstance(type: type, properties: [:])

		for arg in args {
			guard let label = arg.label else {
				fatalError("expected argument label when instantiating \(type)")
			}

			instance.properties[label] = try arg.expr.accept(self, context)
		}

		return .instance(instance)
	}

	func runtimeError(_ err: String) {
		fatalError(err)
	}
}
