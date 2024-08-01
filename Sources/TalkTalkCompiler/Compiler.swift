//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import LLVM
import TalkTalkAnalysis
import TalkTalkSyntax

public struct Compiler: AnalyzedVisitor {
	public class Context {
		var name: String
		var counter: Int = 0
		var environment: LLVM.Function.Environment = .init()
		var lexicalScope: LexicalScope?

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

		func newEnvironment(structType: StructType, in builder: LLVM.Builder) -> Context {
			let context = Context(
				name: structType.name!,
				counter: counter,
				environment: LLVM.Function.Environment(parent: environment)
			)

			for (_, property) in structType.properties {
				context.environment.define(
					property.name,
					as: .getter(
						structType.toLLVM(in: builder),
						property.type.irType(in: builder),
						property.name
					)
				)
			}

			for (_, method) in structType.methods {
				context.environment.define(
					method.name,
					as: .method(
						structType.toLLVM(in: builder),
						MethodType(
							calleeType: structType.toLLVM(in: builder),
							functionType: method.type.irType(in: builder) as! LLVM.FunctionType
						).functionType,
						method.name
					)
				)
			}

			return context
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

	public func compile(optimize: Bool = false) -> LLVM.Module {
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

		if optimize {
			LLVM.ModulePassManager(
				module: module
			).run()
		}

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
		case let callee as LLVM.MetaType:
			return builder.instantiate(struct: callee.type, with: args, vtable: callee.vtable)
		case let callee as LLVM.EmittedMethodValue:
			return builder.call(method: callee, with: args)
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
		case .self:
			fatalError()
		case .method:
			fatalError()
		case .getter:
			fatalError()
		case .structType:
			fatalError()
		case .builtin:
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

		// Define self

		switch binding {
		case let .capture(index, type):
			log(
				"<- loading capture in \(context.name): \(expr.name): slot \(index) in environment struct")
			return builder.load(capture: index, envStructType: type)
		case let .defined(pointer):
			log(
				"<- loading defined binding in \(context.name): \(expr.name): \(type(of: pointer.type)) \(pointer.isHeap ? "from heap \(pointer.ref)" : "from stack")"
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
		case let .structType(type, ptr):
			let vtable = builder.vtable(for: type.typeRef(in: builder.context))!
			return LLVM.MetaType(type: type, ref: ptr, vtable: vtable)
		case let .self(structType):
			let ptr = builder.load(parameter: 0).ref
			return LLVM.EmittedStructPointerValue(type: structType, ref: ptr)
		case .method:
			// Need to figure out how we're going to access the instance here...
			fatalError()
		case let .getter(structType, propertyType, name):
			// Get the instance (we pass it in as the first argument to methods)
			let param = builder.load(parameter: 0)
			let pointer = LLVM.EmittedStructPointerValue(type: structType, ref: param.ref)
			let offset = structType.offset(for: name)

			return builder.load(from: pointer, index: offset, as: propertyType, name: "get_\(name)")
		case let .builtin(name):
			return LLVM.BuiltinValue(type: LLVM.BuiltinType(name: name), ref: builder.mainRef)
		case .function:
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
		case .less:
			.less
		case .lessEqual:
			.lessEqual
		case .greater:
			.greater
		case .greaterEqual:
			.greaterEqual
		case .minus:
				.minus
		case .star:
				.star
		case .slash:
				.slash
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
			functionType,
			parameterNames: funcExpr.params.params.map(\.name),
			envStruct: envStruct
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

	public func visit(_ expr: AnalyzedReturnExpr, _ context: Context) -> any LLVM.EmittedValue {
		fatalError()
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
		switch expr.receiverAnalyzed.accept(self, context) {
		case let receiver as LLVM.EmittedStructPointerValue:
			guard case let .instance(.struct(structType)) = expr.receiverAnalyzed.type else {
				fatalError("cannot access member '\(expr.property)' on non-instance \(expr.receiverAnalyzed.type)")
			}

			if let property = structType.properties[expr.property] {
				let offset = structType.offset(for: property.name)
				let property = structType.properties[expr.property]!
				return builder.load(from: receiver, index: offset, as: property.type.irType(in: builder), name: "member_\(property.name)")
			}

			if let method = structType.methods[expr.property] {
				let vtablePtr = builder.vtable(named: "\(structType.name!)_methodTable")

				// Figure out where in the vtable the function lives
				let offset = structType.offset(method: method.name)

				// Get the function from the vtable
				let type = method.type.irType(in: builder) as! LLVM.FunctionType
				let methodType = type.asMethod(in: builder.context, on: structType.toLLVM(in: builder))
				let function = builder.vtableLookup(vtablePtr, capacity: structType.methods.count, at: offset, as: methodType)

//				let fn = builder.load(from: vtable, at: offset, as: LLVM.TypePointer(type: methodType)) as! LLVM.EmittedFunctionValue

				return LLVM.EmittedMethodValue(function: function, receiver: receiver)
			}

			print(receiver)
		default:
			()
		}

		fatalError("Could not figure out receiver for: \(expr.description)")
	}

	public func visit(_: AnalyzedParamsExpr, _: Context) -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedStructExpr, _ context: Context) -> any LLVM.EmittedValue {
		let structType = expr.structType
		let context = context.newEnvironment(structType: structType, in: builder)

		for (name, property) in structType.properties {
			context.environment.define(
				name,
				as: .getter(
					structType.toLLVM(in: builder),
					property.type.irType(in: builder),
					property.name
				)
			)
		}

		context.environment.define("self", as: .`self`(structType.toLLVM(in: builder)))

		// Need to define the methods and build up a method table
		var emittedMethods: [LLVM.EmittedFunctionValue] = []
		for (name, property) in structType.methods.sorted(by: { structType.offset(method: $0.key) < structType.offset(method: $1.key) }) {
			// TODO: Clean all this up
			let name = "\(structType.name!)_\(name)"
			var funcExpr = property.expr.cast(AnalyzedFuncExpr.self)

			// Add self to the front of the params list
			var paramsAnalyzed = funcExpr.analyzedParams

			// TODO: Need to figure out how to make the first arg here a pointer
//			paramsAnalyzed.paramsAnalyzed = [AnalyzedParam(type: .struct(structType), expr: .int("self"))] + funcExpr.analyzedParams.paramsAnalyzed

			funcExpr.name = name

			let methodFuncExpr = AnalyzedFuncExpr(
				type: .function(name, funcExpr.returnsAnalyzed?.type ?? .void, paramsAnalyzed, []),
				expr: funcExpr,
				analyzedParams: paramsAnalyzed,
				bodyAnalyzed: funcExpr.bodyAnalyzed,
				returnsAnalyzed: funcExpr.returnsAnalyzed,
				environment: funcExpr.environment
			)

			let emitted = visit(methodFuncExpr, context) as! LLVM.EmittedFunctionValue
			emittedMethods.append(emitted)
		}

		let vtable = builder.vtableCreate(emittedMethods, offsets: structType.methodOffsets, name: "\(structType.name!)_methodTable")
		let ref = structType.toLLVM(in: builder).typeRef(in: builder.context)
		builder.saveVtable(for: ref, as: vtable)

		return LLVM.VoidValue()
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
