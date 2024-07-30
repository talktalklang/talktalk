//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import LLVM
import C_LLVM
import TalkTalkSyntax
import TalkTalkAnalysis

public struct Compiler: AnalyzedVisitor {
	public class Context {
		var name: String
		var counter: Int = 0
		var environment: LLVM.Function.Environment = .init()

		init(
			name: String,
			counter: Int = 0,
			environment: LLVM.Function.Environment = .init()
		) {
			self.name = name
			self.counter = counter
			self.environment = environment
		}

		func newEnvironment(name: String) -> Context {
			Context(
				name: name,
				counter: counter,
				environment: LLVM.Function.Environment(parent: environment)
			)
		}

		func nextCount() -> Int {
			counter += 1
			return counter
		}
	}

	let source: String
	let module: LLVM.Module
	let builder: LLVM.Builder
	let verbose: Bool

	public init(_ source: String, verbose: Bool = false) {
		self.source = source
		self.module = LLVM.Module(name: "main", in: .global)
		self.builder = LLVM.Builder(module: module)
		self.verbose = verbose
	}

	public func compile() -> LLVM.Module {
		LLVMInitializeNativeTarget()
		LLVMInitializeNativeAsmParser()
		LLVMInitializeNativeAsmPrinter()

		let lexer = TalkTalkLexer(source)
		var parser = Parser(lexer)
		let parsed = parser.parse()

		if !parser.errors.isEmpty {
			fatalError(parser.errors.description)
		}

		let analyzed = Analyzer.analyze(parsed)
		let context = Context(name: "main")
		_ = analyzed.accept(self, context)

		if verbose {
			module.dump()
		}

		LLVM.ModulePassManager(
			module: module
		).run()

		return module
	}

	public func run() -> Value {
		#if os(Linux)
		return .error("JIT not supported on Linux")
		#else
		if let int = LLVM.JIT().execute(module: compile()) {
			return .int(int)
		} else {
			return .error("Nope.")
		}
		#endif
	}

	public func visit(_ expr: AnalyzedCallExpr, _ context: Context) -> any LLVM.EmittedValue {
		let args = expr.argsAnalyzed.map { $0.expr.accept(self, context) }
		let callee = expr.calleeAnalyzed.accept(self, context)

		switch callee {
		case let callee as LLVM.EmittedFunctionValue:
			return builder.call(callee, with: args)
		case let callee as LLVM.BuiltinValue:
			return builder.call(builtin: callee.type.name, with: args)
		default:
			fatalError("\(callee) not callable")
		}
	}

	public func visit(_ expr: AnalyzedDefExpr, _ context: Context) -> any LLVM.EmittedValue {
		let value = expr.valueAnalyzed.accept(self, context)
		guard let variable = context.environment.get(expr.name.lexeme) else {
			fatalError("Undefined variable: \(expr.name.lexeme)")
		}

		switch variable {
		case let .declared(pointer):
			_ = builder.store(value, to: pointer)
			context.environment.define(expr.name.lexeme, as: pointer)
		case let .defined(pointer):
			_ = builder.store(value, to: pointer)
		case let .capture(index, type):
			builder.store(capture: value, at: index, as: type)
		case .builtin(_):
			fatalError("Cannot assign to a builtin")
		case .parameter:
			fatalError("Cannot assign to a param")
		case .function:
			fatalError("hang on")
		}

		return value
	}

	public func visit(_ err: AnalyzedErrorSyntax, _: Context) -> any LLVM.EmittedValue {
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
		guard let binding = context.environment.get(expr.name) else {
			fatalError("undefined variable: \(expr.name)")
		}

		switch binding {
		case let .capture(index, type):
			log(
				"<- loading capture in \(context.name): \(expr.name): slot \(index) in environment struct")
			return builder.load(capture: index, envStructType: type)
		case let .defined(pointer):
			log(
				"<- loading defined binding in \(context.name): \(expr.name): \(type(of: pointer.type)) \(pointer.isHeap ? "from heap \(pointer.ref)" : "")"
			)
			return builder.load(pointer: pointer, name: expr.name)
		case let .parameter(index, _):
			log("<- loading parameter in \(context.name): \(expr.name): \(index)")
			return builder.load(parameter: index)
		case let .declared(pointer):
			log(
				"<- loading declared binding in \(context.name): \(expr.name): \(pointer.type) \(pointer.isHeap ? "from heap \(pointer.ref)" : "")"
			)
			return builder.load(pointer: pointer, name: expr.name)
		case let .builtin(name):
			return LLVM.BuiltinValue(type: LLVM.BuiltinType(name: name), ref: builder.mainRef)
		case .function(_):
			fatalError()
		}
	}

	public func visit(_ expr: AnalyzedBinaryExpr, _ context: Context) -> any LLVM.EmittedValue {
		let type =
			switch expr.type {
			case .int:
				LLVM.EmittedIntValue.self
			default:
				fatalError()
			}

		let op: LLVM.BinaryOperator = switch expr.op {
		case .plus:
			.add
		case .equalEqual:
			.equals
		case .bangEqual:
			.notEquals
		}

		let lhs = expr.lhsAnalyzed.accept(self, context).as(type)
		let rhs = expr.rhsAnalyzed.accept(self, context).as(type)

		return builder.binaryOperation(op, lhs, rhs)
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
		let context = context.newEnvironment(name: funcExpr.name ?? funcExpr.autoname)

		if funcExpr.name == "main" {
			return main(funcExpr, context)
		}

		let envStruct = emitEnvironment(funcExpr, context)

		let emittedFunction = builder.define(
			functionType, parameterNames: funcExpr.params.params.map(\.name), envStruct: envStruct
		) {
			allocateLocals(funcExpr: funcExpr, context: context)

			for (i, param) in funcExpr.analyzedParams.paramsAnalyzed.enumerated() {
				context.environment.parameter(param.name, type: irType(for: param.type), at: i)
			}

			let returnValue = visit(funcExpr.bodyAnalyzed, context)

			if returnValue.type.isVoid {
				builder.emitVoidReturn()
			} else {
				_ = builder.emit(return: returnValue)
			}
		}

		return emittedFunction
	}

	public func visit(_ expr: AnalyzedBlockExpr, _ context: Context) -> any LLVM.EmittedValue {
		var returnValue: (any LLVM.EmittedValue)? = nil

		for expr in expr.exprsAnalyzed {
			returnValue = expr.accept(self, context)
		}

		return returnValue ?? LLVM.VoidValue()
	}

	public func visit(_ expr: AnalyzedWhileExpr, _ context: Context) -> any LLVM.EmittedValue {
		builder.branch {
			expr.conditionAnalyzed.accept(self, context)
		} repeating: {
			_ = expr.bodyAnalyzed.accept(self, context)
		}
	}

	public func visit(_ expr: AnalyzedMemberExpr, _ context: Context) -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_: AnalyzedParamsExpr, _: Context) -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedStructExpr, _ context: Context) -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedDeclBlock, _ context: Context) -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedVarDecl, _ context: Context) -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedLetDecl, _ context: Context) -> any LLVM.EmittedValue {
		fatalError()
	}
}
