//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import LLVM

public struct Compiler: AnalyzedVisitor {
	public class Context {
		var counter: Int = 0
		var environment: LLVM.Function.Environment = .init()

		init(counter: Int = 0, environment: LLVM.Function.Environment = .init()) {
			self.counter = counter
			self.environment = environment
		}

		func newEnvironment() -> Context {
			Context(counter: counter, environment: LLVM.Function.Environment(parent: environment))
		}

		func nextCount() -> Int {
			counter += 1
			return counter
		}
	}

	let source: String
	let module: LLVM.Module
	let builder: LLVM.Builder

	public init(_ source: String) {
		self.source = source
		self.module = LLVM.Module(name: "main", in: .global)
		self.builder = LLVM.Builder(module: module)
	}

	public func run() -> Slips.Value {
		let lexer = Lexer(source)
		var parser = Parser(lexer)
		let parsed = parser.parse()

		let analyzed = Analyzer.analyze(parsed)

		let context = Context()

		main(in: builder) {
			var lastReturn: (any LLVM.IR)?

			for expr in analyzed {
				lastReturn = expr.accept(self, context)
			}

			if let lastReturnPointer = lastReturn as? any LLVM.StoredPointer {
				return builder.load(pointer: lastReturnPointer)
			}

			return lastReturn as! any LLVM.IRValue
		}

		module.dump()

		if let int = LLVM.JIT().execute(module: module) {
			return .int(int)
		} else {
			return .error("Nope.")
		}
	}

	public func visit(_ expr: AnalyzedCallExpr, _ context: Context) -> any LLVM.EmittedValue {
		if case let .defined(functionPointer) = context.environment.get(expr.callee.description) {
			return builder.call(functionPointer, with: expr.argsAnalyzed.map { $0.accept(self, context) })
		} else if expr.callee.description == "call" {
			// Get the callable thing
			let callable = expr.argsAnalyzed[0]
			let emittedCallable = callable.accept(self, context) as! LLVM.EmittedFunctionValue
			let args = expr.argsAnalyzed[1 ..< expr.argsAnalyzed.count]
			return builder.call(emittedCallable, with: args.map { $0.accept(self, context) })
		} else {
			builder.dump()
			fatalError("No support for calling anonmous functions yet")
		}
	}

	public func visit(_ expr: AnalyzedDefExpr, _ context: Context) -> any LLVM.EmittedValue {
		let value = expr.valueAnalyzed.accept(self, context)

		switch value {
		case let value as LLVM.EmittedIntValue:
			let stackValue = builder.store(stackValue: value, name: expr.name.lexeme)
			context.environment.define(expr.name.lexeme, as: stackValue)
		case let value as LLVM.EmittedFunctionValue:
			let stackValue = builder.store(stackValue: value, name: expr.name.lexeme)
			context.environment.define(expr.name.lexeme, as: stackValue)
		default:
			fatalError()
		}

		return value
	}

	public func visit(_: AnalyzedErrorExpr, _: Context) -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedLiteralExpr, _: Context) -> any LLVM.EmittedValue {
		switch expr.value {
		case let .int(int):
			builder.emit(constant: LLVM.IntType.i8.constant(int))
		case let .bool(bool):
			builder.emit(constant: LLVM.IntType.i1.constant(bool ? 1 : 0))
		default:
			fatalError()
		}
	}

	public func visit(_ expr: AnalyzedVarExpr, _ context: Context) -> any LLVM.EmittedValue {
		if let binding = context.environment.get(expr.name) {
			switch binding {
			case let .defined(pointer):
				builder.load(pointer: pointer)
			case let .parameter(index):
				builder.load(parameter: index)
			case .capture:
				fatalError("closures not implemented yet")
			}

		} else {
			fatalError("undefined variable: \(expr.name)")
		}
	}

	public func visit(_ expr: AnalyzedAddExpr, _ context: Context) -> any LLVM.EmittedValue {
		let lhs = expr.lhsAnalyzed.accept(self, context) as! LLVM.EmittedIntValue
		let rhs = expr.rhsAnalyzed.accept(self, context) as! LLVM.EmittedIntValue

		return builder.binaryOperation(
			.add,
			lhs,
			rhs
		)
	}

	public func visit(_ expr: AnalyzedIfExpr, _ context: Context) -> any LLVM.EmittedValue {
		builder.branch {
			expr.conditionAnalyzed.accept(self, context)
		} consequence: {
			expr.consequenceAnalyzed.accept(self, context)
		} alternative: {
			expr.alternativeAnalyzed.accept(self, context)
		}
	}

	public func visit(_ expr: AnalyzedFuncExpr, _ context: Context) -> any LLVM.EmittedValue {
		let name = expr.name
		let params = expr.params.names.map { _ in LLVM.IntType.i32 }
		let context = context.newEnvironment()

		let functionType = LLVM.FunctionType(
			name: name,
			returnType: getTypeOf(expr: expr.body.last!, context: context),
			parameterTypes: params,
			isVarArg: false
		)

		let function = LLVM.Function(type: functionType, environment: context.environment)

		for (i, param) in expr.params.names.enumerated() {
			context.environment.parameter(param.name, at: i)
		}

		return builder.define(function, parameterNames: expr.params.names.map(\.name)) {
			for expr in expr.bodyAnalyzed {
				_ = builder.emit(return: expr.accept(self, context))
			}
		}
	}

	public func visit(_: AnalyzedParamsExpr, _: Context) -> any LLVM.EmittedValue {
		fatalError()
	}
}
