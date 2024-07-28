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

		_ = analyzed.accept(self, context)

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
		case let callee as any LLVM.FunctionPointer:
			return builder.call(callee, with: args)
		default:
			fatalError()
		}

		fatalError()
	}

	public func visit(_ expr: AnalyzedDefExpr, _ context: Context) -> any LLVM.EmittedValue {
		let value = expr.valueAnalyzed.accept(self, context)
		let variable = context.environment.get(expr.name.lexeme)

		switch variable {
		case let .declared(pointer):
			_ = builder.store(value, to: pointer)
			context.environment.define(expr.name.lexeme, as: pointer)
		case let .defined(pointer):
			_ = builder.store(value, to: pointer)
		case .parameter(_):
			fatalError("not yet")
		default:
			fatalError("not yet")
		}

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
			print("<- loading binding: \(expr.name): \(type(of: pointer.type)) \(pointer.isHeap ? "from heap \(pointer.ref)" : "")")
			return builder.load(pointer: pointer, name: expr.name)
		case let .parameter(index, _):
			print("<- loading parameter: \(expr.name): \(index)")
			return builder.load(parameter: index)
		case let .declared(pointer):
			print("<- loading parameter: \(expr.name): \(pointer.type) \(pointer.isHeap ? "from heap \(pointer.ref)" : "")")
			fatalError("uninitialized variable: \(expr.name)")
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

	public func visit(_ funcExpr: AnalyzedFuncExpr, _ context: Context) -> any LLVM.EmittedValue {
		let functionType = irType(for: funcExpr).as(LLVM.FunctionType.self)
		let context = context.newEnvironment()

		if funcExpr.name == "main" {
			return main(funcExpr, context)
		}

		let envStruct = emitEnvironment(funcExpr, context)

		let emittedFunction = builder.define(functionType, parameterNames: funcExpr.params.params.map(\.name), envStruct: envStruct) {
			for (i, param) in funcExpr.analyzedParams.paramsAnalyzed.enumerated() {
				context.environment.parameter(param.name, type: irType(for: param.type), at: i)
			}

			var returnValue: (any LLVM.EmittedValue)? = nil
			for expr in funcExpr.bodyAnalyzed {
				returnValue = expr.accept(self, context)
			}

			if let returnValue {
				_ = builder.emit(return: returnValue)
			} else {
				builder.emitVoidReturn()
			}
		}

		return emittedFunction
	}

	public func visit(_: AnalyzedParamsExpr, _: Context) -> any LLVM.EmittedValue {
		fatalError()
	}

	// MARK: Helpers

	func emitEnvironment(_ funcExpr: AnalyzedFuncExpr, _ context: Context) -> LLVM.CapturesStruct {
		// Figure out which of this function's values are captured by children and malloc some heap space
		// for them.
		for binding in funcExpr.environment.bindings {
			if binding.isCaptured {
				let storage = builder.malloca(type: irType(for: binding.expr), name: binding.name)
				print("-> emitting binding in \(funcExpr.name): \(binding.name) \(binding.expr.description) (\(storage.ref))")
				context.environment.declare(binding.name, as: storage)
			} else {
				let storage = builder.alloca(type: irType(for: binding.expr), name: binding.name)
				print("-> emitting binding in \(funcExpr.name): \(binding.name) \(binding.expr.description) (\(storage.ref))")
				context.environment.declare(binding.name, as: storage)
			}
		}

		// Create a closure for this function, moving locals to the heap. For values already on the heap,
		// just reuse the values.
		var captures: [(String, any LLVM.StoredPointer)] = []
		for capture in funcExpr.environment.captures {
			captures.append((capture.name, context.environment.capture(capture.name, with: builder)))
		}

		return createEnvironmentStruct(from: captures)
	}

	func createEnvironmentStruct(from captures: [(String, any LLVM.StoredPointer)]) -> LLVM.CapturesStruct {
		let type = LLVM.CapturesStructType(types: captures.map { $0.1.type })
		var offsets: [String: Int] = [:]
		var capturePointers: [any LLVM.StoredPointer] = []
		for (i, capture) in captures.enumerated() {
			offsets[capture.0] = i
			capturePointers.append(capture.1)
		}

		let pointer = builder.struct(type: type, values: captures)
		let value = LLVM.CapturesStruct(type: type, offsets: offsets, captures: capturePointers, ref: pointer.ref)

		return value
	}

	func main(_ funcExpr: AnalyzedFuncExpr, _ context: Context) -> any LLVM.EmittedValue {
		var functionType = irType(for: funcExpr).as(LLVM.FunctionType.self)
		functionType.name = funcExpr.name

		let main = builder.main(functionType: functionType)

		_ = emitEnvironment(funcExpr, context)

		var lastReturn: (any LLVM.EmittedValue)?
		for expr in funcExpr.bodyAnalyzed {
			lastReturn = expr.accept(self, context)
		}

		if let lastReturn {
			_ = builder.emit(return: lastReturn)
		} else {
			_ = builder.emit(constant: LLVM.IntType.i32.constant(1))
		}

		return main
	}

	func irType(for type: ValueType) -> any LLVM.IRType {
		switch type {
		case .int:
			LLVM.IntType.i32
		case let .function(name, returns, params):
			LLVM.FunctionType(
				name: name,
				returnType: irType(for: returns),
				parameterTypes: params.paramsAnalyzed.map { irType(for: $0.type) },
				isVarArg: false,
				envStructType: nil
			)
		default:
			fatalError()
		}
	}

	func irType(for expr: AnalyzedExpr) -> any LLVM.IRType {
		switch expr {
		case _ where expr.type == .int:
			return LLVM.IntType.i32
		case let expr as AnalyzedCallExpr:
			return irType(for: expr.type)
		case let expr as AnalyzedFuncExpr:
			let returnType = if let returns = expr.returnsAnalyzed {
				irType(for: returns)
			} else {
				LLVM.VoidType()
			}

			var functionType = LLVM.FunctionType(
				name: expr.name,
				returnType: returnType,
				parameterTypes: expr.analyzedParams.paramsAnalyzed.map { irType(for: $0.type) },
				isVarArg: false,
				envStructType: LLVM.CapturesStructType(types: expr.environment.captures.map { irType(for: $0.binding.type) })
			)

			functionType.name = expr.name

			return functionType
		default:
			fatalError()
		}
	}
}
