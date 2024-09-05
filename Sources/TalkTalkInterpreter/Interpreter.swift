//
//  Interpreter.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkAnalysis
import TalkTalkSyntax
import TypeChecker

// swiftlint:disable fatal_error force_unwrapping force_try force_cast

public struct InterpreterStruct {
	var name: String
	var properties: [String: Value]
}

public struct Interpreter: AnalyzedVisitor {
	enum Return: Error, @unchecked Sendable {
		case returning(Value)
	}

	let parsed: [any AnalyzedSyntax]

	public init(_ code: String) throws {
		let parsed = try Parser.parse(.init(path: "interpreter", text: code))
		let context = try Inferencer(imports: []).infer(parsed)
		self.parsed = try SourceFileAnalyzer.analyze(
			parsed,
			in: .init(inferenceContext: context, symbolGenerator: .init(moduleName: "Interpreter", parent: nil))
		)
	}

	public func evaluate() throws -> Value {
		var last: Value = .none
		let rootScope = Scope()

		for expr in parsed {
			do {
				last = try expr.accept(self, rootScope)
			} catch let Return.returning(value) {
				return value
			}
		}

		return last
	}

	public func visit(_ expr: AnalyzedArrayLiteralExpr, _ context: Scope) throws -> Value {
		fatalError("TODO")
	}

	public func visit(_ expr: AnalyzedTypeExpr, _ context: Scope) throws -> Value {
		context.lookup(expr.identifier.lexeme)
	}

	public func visit(_ expr: AnalyzedExprStmt, _ context: Scope) throws -> Value {
		try expr.exprAnalyzed.accept(self, context)
	}

	public func visit(_ expr: AnalyzedParam, _: Scope) throws -> Value {
		.none
	}

	public func visit(_: AnalyzedImportStmt, _: Scope) throws -> Value {
		.none
	}

	public func visit(_: AnalyzedIdentifierExpr, _: Scope) throws -> Value {
		.none
	}

	public func visit(_: AnalyzedGenericParams, _: Scope) throws -> Value {
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

		switch expr.op {
		case .plus:
			return lhs.add(rhs)
		case .equalEqual:
			return .bool(lhs == rhs)
		case .bangEqual:
			return .bool(lhs != rhs)
		case .less:
			return .bool(lhs < rhs)
		case .lessEqual:
			return .bool(lhs <= rhs)
		case .greater:
			return .bool(lhs > rhs)
		case .greaterEqual:
			return .bool(lhs >= rhs)
		case .minus:
			return lhs.minus(rhs)
		case .star:
			return lhs.times(rhs)
		case .slash:
			return lhs.div(rhs)
		case .is:
			return .bool(lhs.type == rhs)
		}
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
		} else if case .builtin = callee {
			_ = try expr.argsAnalyzed.map { try $0.expr.accept(self, scope) }
			return .none
		} else {
			fatalError("\(callee) not callable")
		}
	}

	public func visit(_ expr: AnalyzedDefExpr, _ scope: Scope) throws -> Value {
		try scope.define(expr.receiver.cast(VarExprSyntax.self).name, expr.valueAnalyzed.accept(self, scope))
	}

	public func visit(_ expr: AnalyzedLiteralExpr, _: Scope) throws -> Value {
		switch expr.value {
		case let .bool(bool):
			.bool(bool)
		case let .int(int):
			.int(int)
		case let .string(string):
			.string(string)
		case .none:
			.none
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
			_ = scope.define(name.lexeme, .fn(Closure(funcExpr: expr, environment: childScope)))
		}

		return .fn(Closure(funcExpr: expr, environment: childScope))
	}

	public func visit(_: AnalyzedParamsExpr, _: Scope) throws -> Value {
		fatalError("unreachable")
	}

	public func visit(_ expr: ParamSyntax, _ context: Scope) throws -> Value {
		context.lookup(expr.name)
	}

	public func visit(_ expr: AnalyzedWhileStmt, _ context: Scope) throws -> Value {
		var lastResult: Value = .none
		while try expr.conditionAnalyzed.accept(self, context) == .bool(true) {
			lastResult = try visit(expr.bodyAnalyzed, context)
		}
		return lastResult
	}

	public func visit(_ expr: AnalyzedBlockStmt, _ context: Scope) throws -> Value {
		try lastResult(of: expr.stmtsAnalyzed, in: context)
	}

	public func visit(_ expr: AnalyzedErrorSyntax, _: Scope) throws -> Value {
		.error(expr.message)
	}

	public func visit(_ expr: AnalyzedStructExpr, _ context: Scope) throws -> Value {
		var type = StructType(
			name: expr.name,
			properties: [:],
			methods: [:]
		)

		for decl in expr.bodyAnalyzed.declsAnalyzed {
			if let exprStmt = decl as? AnalyzedExprStmt,
			   let funcExpr = exprStmt.exprAnalyzed as? AnalyzedFuncExpr
			{
				type.methods[funcExpr.name!.lexeme] = funcExpr
			}
		}

		let retVal: Value = .struct(type)

		if let name = expr.name {
			_ = context.define(name, retVal)
		}

		return retVal
	}

	public func visit(_: AnalyzedInitDecl, _: Scope) throws -> Value {
		fatalError("TODO")
	}

	public func visit(_ expr: AnalyzedReturnStmt, _ context: Scope) throws -> Value {
		let value = try expr.valueAnalyzed?.accept(self, context)
		throw Return.returning(value ?? .none)
	}

	public func visit(_ expr: AnalyzedDeclBlock, _ context: Scope) throws -> Value {
		for decl in expr.declsAnalyzed {
			_ = try decl.accept(self, context)
		}

		return .none
	}

	public func visit(_ expr: AnalyzedVarDecl, _ context: Scope) throws -> Value {
		if let value = expr.valueAnalyzed {
			return try context.define(expr.name, value.accept(self, context))
		}

		return .none
	}

	public func visit(_ expr: AnalyzedLetDecl, _ context: Scope) throws -> Value {
		if let value = expr.valueAnalyzed {
			return try context.define(expr.name, value.accept(self, context))
		}

		return .none
	}

	public func visit(_ expr: AnalyzedIfStmt, _ context: Scope) throws -> Value {
		let condition = try expr.conditionAnalyzed.accept(self, context)

		if condition.isTruthy {
			_ = try expr.consequenceAnalyzed.accept(self, context)
		} else {
			_ = try expr.alternativeAnalyzed?.accept(self, context)
		}

		return .none
	}

	public func visit(_ expr: AnalyzedStructDecl, _ context: Scope) throws -> Value {
		var type = StructType(
			name: expr.name,
			properties: [:],
			methods: [:]
		)

		for decl in expr.bodyAnalyzed.declsAnalyzed {
			if let funcExpr = decl as? AnalyzedFuncExpr {
				type.methods[funcExpr.name!.lexeme] = funcExpr
			}
		}

		let retVal: Value = .struct(type)

		_ = context.define(expr.name, retVal)

		return retVal
	}

	public func visit(_ expr: AnalyzedSubscriptExpr, _ context: Scope) throws -> Value {
		fatalError("TODO")
	}

	public func visit(_ expr: AnalyzedDictionaryLiteralExpr, _ context: Scope) throws -> Value {
		fatalError("TODO")
	}

	public func visit(_ expr: AnalyzedDictionaryElementExpr, _ context: Scope) throws -> Value {
		fatalError("TODO")
	}

	public func visit(_ expr: AnalyzedProtocolDecl, _ context: Scope) throws -> Value {
		return .none
	}

	public func visit(_ expr: AnalyzedProtocolBodyDecl, _ context: Scope) throws -> Value {
		return .none
	}

	public func visit(_ expr: AnalyzedFuncSignatureDecl, _ context: Scope) throws -> Value {
		return .none
	}

	public func visit(_ expr: AnalyzedEnumDecl, _ context: Scope) throws -> Value {
		#warning("Generated by Dev/generate-type.rb")
		return .none
	}

	public func visit(_ expr: AnalyzedEnumCaseDecl, _ context: Scope) throws -> Value {
		#warning("Generated by Dev/generate-type.rb")
		return .none
	}

	// GENERATOR_INSERTION

	private func lastResult(of exprs: [any AnalyzedSyntax], in context: Scope) throws -> Value {
		var lastResult: Value = .none
		for expr in exprs {
			lastResult = try expr.accept(self, context)
		}
		return lastResult
	}

	func call(
		_ funcExpr: AnalyzedFuncExpr, on instance: StructInstance, with args: [any AnalyzedExpr]
	) throws -> Value {
		let scope = Scope()
		_ = scope.define("self", .instance(instance))

		for (i, argument) in args.enumerated() {
			_ = try scope.define(
				funcExpr.params.params[i].name,
				argument.accept(self, scope)
			)
		}

		var lastReturn: Value = .none

		for expr in funcExpr.bodyAnalyzed.stmtsAnalyzed {
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
			_ = try scope.define(
				closure.funcExpr.params.params[i].name,
				argument.accept(self, scope)
			)
		}

		var lastReturn: Value = .none

		for expr in closure.funcExpr.bodyAnalyzed.stmtsAnalyzed {
			do {
				lastReturn = try expr.accept(self, scope)
			} catch let Return.returning(value) {
				return value
			}
		}

		return lastReturn
	}

	func instantiate(_ type: StructType, with args: [AnalyzedArgument], in context: Scope) throws
		-> Value
	{
		var instance = StructInstance(type: type, properties: [:])

		for arg in args {
			guard let label = arg.label else {
				fatalError("expected argument label when instantiating \(type)")
			}

			instance.properties[label.lexeme] = try arg.expr.accept(self, context)
		}

		return .instance(instance)
	}

	func runtimeError(_ err: String) {
		fatalError(err)
	}
}
