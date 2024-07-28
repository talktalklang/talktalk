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
		let args = expr.argsAnalyzed.map { $0.accept(self, context) }
		let callee = expr.calleeAnalyzed.accept(self, context)

		switch callee {
		case let callee as LLVM.EmittedFunctionValue:
			return builder.call(callee, with: args)
		default:
			fatalError()
		}

		fatalError()
	}

	public func visit(_ expr: AnalyzedDefExpr, _ context: Context) -> any LLVM.EmittedValue {
		let value = expr.valueAnalyzed.accept(self, context)

		let stored: any LLVM.StoredPointer = switch value {
		case let value as LLVM.EmittedIntValue:
			builder.store(stackValue: value, name: expr.name.lexeme)
		case let value as LLVM.EmittedFunctionValue:
			builder.store(stackValue: value, name: expr.name.lexeme)
		case let value as any LLVM.StoredPointer:
			value
		default:
			fatalError()
		}

		context.environment.define(
			expr.name.lexeme,
			as: stored
		)

		return value
	}

	public func visit(_: AnalyzedErrorExpr, _: Context) -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedLiteralExpr, _: Context) -> any LLVM.EmittedValue {
		switch expr.value {
		case let .int(int):
			builder.emit(constant: LLVM.IntType.i32.constant(int))
		case let .bool(bool):
			builder.emit(constant: LLVM.IntType.i1.constant(bool ? 1 : 0))
		default:
			fatalError()
		}
	}

	public func visit(_ expr: AnalyzedVarExpr, _ context: Context) -> any LLVM.EmittedValue {
		switch context.environment.get(expr.name) {
		case let .defined(pointer):
			builder.load(pointer: pointer, name: expr.name)
		case let .parameter(index):
			builder.load(parameter: index)
		case .capture:
			fatalError()
		default:
			fatalError()
		}
	}

	public func visit(_ expr: AnalyzedAddExpr, _ context: Context) -> any LLVM.EmittedValue {
		let type = switch expr.type {
		case .int:
			LLVM.EmittedIntValue.self
		default:
			fatalError()
		}

		let lhs = expr.lhsAnalyzed.accept(self, context).as(type)
		let rhs = expr.rhsAnalyzed.accept(self, context).as(type)

		return builder.binaryOperation(.add, lhs, rhs)
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
		let functionType = irType(for: expr).as(LLVM.FunctionType.self)
		let function = LLVM.Function(type: functionType)

		let emittedFunction = builder.define(function, parameterNames: expr.params.params.map(\.name)) {
			for (i, param) in expr.analyzedParams.paramsAnalyzed.enumerated() {
				context.environment.parameter(param.name, at: i)
			}

			var returnValue: (any LLVM.EmittedValue)? = nil
			for expr in expr.bodyAnalyzed {
				returnValue = expr.accept(self, context)
			}

			if let returnValue {
				_ = builder.emit(return: returnValue)
			} else {
				builder.emitVoidReturn()
			}
		}

		let pointer = builder.store(stackValue: emittedFunction, name: expr.name)

		return pointer
	}

	public func visit(_: AnalyzedParamsExpr, _: Context) -> any LLVM.EmittedValue {
		fatalError()
	}

	// MARK: Helpers

	func irType(for type: ValueType) -> any LLVM.IRType {
		switch type {
		case .int:
			LLVM.IntType.i32
		case let .function(returns, params):
			LLVM.FunctionType(
				name: type.description,
				returnType: irType(for: returns),
				parameterTypes: params.paramsAnalyzed.map { irType(for: $0.type) },
				isVarArg: false
			)
		default:
			fatalError()
		}
	}

	func irType(for expr: AnalyzedExpr) -> any LLVM.IRType {
		switch expr {
		case _ where expr.type == .int:
			return LLVM.IntType.i32
		case let expr as AnalyzedFuncExpr:
			let returnType = if let returns = expr.returnsAnalyzed {
				irType(for: returns)
			} else {
				LLVM.VoidType()
			}

			return LLVM.FunctionType(
				name: expr.name,
				returnType: returnType,
				parameterTypes: expr.analyzedParams.paramsAnalyzed.map { irType(for: $0.type) },
				isVarArg: false
			)
		default:
			fatalError()
		}
	}
}
