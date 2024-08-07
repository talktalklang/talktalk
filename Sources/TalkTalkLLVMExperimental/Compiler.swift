//
//  Compiler.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import LLVM
import C_LLVM
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
							functionType: (method.type.irType(in: builder) as! LLVM.ClosureType).functionType
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

	public func compile(optimize: Bool = false) throws -> LLVM.Module {
		let lexer = TalkTalkLexer(source)
		var parser = Parser(lexer)
		let parsed = parser.parse()

		if !parser.errors.isEmpty {
			fatalError(parser.errors.description)
		}

		let analyzed = try Analyzer.analyze(parsed)
		let context = Context(name: "main")
		_ = try analyzed.accept(self, context)

//		LLVM.ModulePassManager(
//			module: module
//		).run()

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

	public func run() -> TalkTalkAnalysis.Value {
		#if os(Linux)
		return .error("JIT not supported on Linux")
		#elseif EXPERIMENTAL_LLVM_ENABLED
		if let int = try! LLVM.JIT().execute(module: compile()) {
			return .int(int)
		} else {
			return .error("Nope.")
		}
		#else
		return .error("Nope")
		#endif
	}

	public func visit(_ expr: AnalyzedUnaryExpr, _ context: Context) throws -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedCallExpr, _ context: Context) throws -> any LLVM.EmittedValue {
		let args = try expr.argsAnalyzed.map { try $0.expr.accept(self, context) }
		let callee = try expr.calleeAnalyzed.accept(self, context)

		switch callee {
		case let callee as LLVM.EmittedClosureValue:
			return builder.call(closure: callee, with: args)
		case let callee as LLVM.BuiltinValue:
			return builder.call(builtin: callee.type.name, with: args)
		case let callee as LLVM.MetaType:
			return builder.instantiate(struct: callee.type, with: args, vtable: callee.vtable)
		case let callee as LLVM.EmittedStaticMethod:
			return builder.callStatic(method: callee, with: args)
		case let callee as LLVM.EmittedStaticFunction:
			return builder.callStatic(function: callee, with: args)
		case let callee as LLVM.EmittedMethodValue:
			return builder.call(method: callee, with: args)
		default:
			fatalError("\(callee) not callable")
		}
	}

	public func visit(_ expr: TalkTalkAnalysis.AnalyzedIdentifierExpr, _ context: Context) throws -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedDefExpr, _ context: Context) throws -> any LLVM.EmittedValue {
		let value = try expr.valueAnalyzed.accept(self, context)
		guard let variable = context.environment.get(expr.name.lexeme) else {
			fatalError("Undefined variable: \(expr.name.lexeme)")
		}

		switch variable {
		case let .declared(pointer):
			_ = builder.store(value, to: pointer)
			context.environment.define(expr.name.lexeme, as: pointer)
		case let .defined(pointer):
			_ = builder.store(value, to: pointer)
		case let .capture(index, closureType):
			builder.store(capture: value, at: index, closureType: closureType)
		case .staticFunction(_, _):
			()
		case let .closure(closureValue):
			()
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
		}

		return value
	}

	public func visit(_ err: AnalyzedErrorSyntax, _: Context) throws -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedLiteralExpr, _: Context) throws -> any LLVM.EmittedValue {
		switch expr.value {
		case let .int(int):
			builder.emit(constant: LLVM.IntType.i32.constant(int))
		case let .bool(bool):
			builder.emit(constant: LLVM.IntType.i1.constant(bool ? 1 : 0))
		default:
			fatalError()
		}
	}

	public func visit(_ expr: AnalyzedVarExpr, _ context: Context) throws -> any LLVM.EmittedValue {
		guard let binding = context.environment.get(expr.name) else {
			fatalError("undefined variable: \(expr.name)")
		}

		switch binding {
		case let .capture(index, type):
			log(
				"<- loading capture in \(context.name): \(expr.name): slot \(index) in environment struct")
			return builder.load(capture: index, closureType: type)
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
			return LLVM.MetaType(type: type, ref: ptr, vtable: nil)
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
		case let .staticFunction(type, ref):
			return LLVM.EmittedStaticFunction(type: type, ref: ref)
		case let .closure(closureType, closureRef):
			return LLVM.EmittedClosureValue(type: closureType, ref: closureRef)
		}
	}

	public func visit(_ expr: AnalyzedBinaryExpr, _ context: Context) throws -> any LLVM.EmittedValue {
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

		let lhs = try expr.lhsAnalyzed.accept(self, context).as(type)
		let rhs = try expr.rhsAnalyzed.accept(self, context).as(type)

		return builder.binaryOperation(op, lhs, rhs)
	}

	public func visit(_ expr: AnalyzedIfExpr, _ context: Context) throws -> any LLVM.EmittedValue {
		try builder.branch {
			try expr.conditionAnalyzed.accept(self, context)
		} consequence: {
			try expr.consequenceAnalyzed.accept(self, context)
		} alternative: {
			try expr.alternativeAnalyzed.accept(self, context)
		}
	}

	public func visit(_ funcExpr: AnalyzedFuncExpr, _ context: Context) throws -> any LLVM.EmittedValue {
		let type = irType(for: funcExpr)
		let functionType = if let type = type as? LLVM.FunctionType {
			type
		} else if let type = type as? LLVM.ClosureType {
			type.functionType
		} else {
			fatalError()
		}

		let outerContext = context
		let context = context.newEnvironment(name: funcExpr.name?.lexeme ?? funcExpr.autoname)

		if funcExpr.name?.lexeme == "main" {
			return try main(funcExpr, context)
		}

		let closure = captureClosure(funcExpr, context)
		let closurePointer = builder.createClosurePointer(
				name: functionType.name,
				functionType: functionType,
				captures: closure.captures
			)

		_ = try builder.define(
			functionType,
			parameterNames: funcExpr.params.params.map(\.name),
			closurePointer: closurePointer
		) {
			allocateLocals(funcExpr: funcExpr, closurePointer: closurePointer, context: context)
			// Update the binding with the ref
			outerContext.environment.define(funcExpr.name?.lexeme ?? funcExpr.autoname, as: .closure(closurePointer.type, closurePointer.ref))

			for (i, param) in funcExpr.analyzedParams.paramsAnalyzed.enumerated() {
				context.environment.parameter(param.name, type: irType(for: param.type), at: i)
			}

			if let lexicalScope = funcExpr.environment.getLexicalScope() {
				// Define `self` if we're in a lexial scope
				context.environment.define("self", as: .self(lexicalScope.scope.toLLVM(in: builder)))
			}

			let returnValue = try visit(funcExpr.bodyAnalyzed, context)

			if returnValue.type.isVoid {
				builder.emitVoidReturn()
			} else {
				_ = builder.emit(return: returnValue)
			}
		}

		return closurePointer
	}

	public func visit(_ expr: AnalyzedReturnExpr, _ context: Context) throws -> any LLVM.EmittedValue {
		let retval: any LLVM.EmittedValue = try expr.valueAnalyzed?.accept(self, context) ?? LLVM.VoidValue()

		return LLVM.EmittedReturnValue(value: retval)
	}

	public func visit(_ expr: AnalyzedBlockExpr, _ context: Context) throws -> any LLVM.EmittedValue {
		var returnValue: (any LLVM.EmittedValue)? = nil

		for expr in expr.exprsAnalyzed {
			returnValue = try expr.accept(self, context)

			if let returnValue = returnValue as? LLVM.EmittedReturnValue {
				return returnValue.value
			}
		}

		return returnValue ?? LLVM.VoidValue()
	}

	public func visit(_ expr: AnalyzedWhileExpr, _ context: Context) throws -> any LLVM.EmittedValue {
		try builder.branch {
			try expr.conditionAnalyzed.accept(self, context)
		} repeating: {
			_ = try expr.bodyAnalyzed.accept(self, context)
		}
	}

	public func visit(_ expr: AnalyzedMemberExpr, _ context: Context) throws -> any LLVM.EmittedValue {
		switch try expr.receiverAnalyzed.accept(self, context) {
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
				// Vtable stuff
				// let vtablePtr = builder.vtable(named: "\(structType.name!)_methodTable")
				//
				// // Figure out where in the vtable the function lives
				// let offset = structType.offset(method: method.name)
				//
				// // Get the function from the vtable
				// let type = method.type.irType(in: builder) as! LLVM.FunctionType
				// let methodType = type.asMethod(in: builder.context, on: structType.toLLVM(in: builder))
				// let function = builder.vtableLookup(vtablePtr, capacity: structType.methods.count, at: offset, as: methodType)

				// let fn = builder.load(from: vtable, at: offset, as: LLVM.TypePointer(type: methodType)) as! LLVM.EmittedFunctionValue

				// TODO: Introduce a Method type that can generate this name
				let name = "\(structType.name!)_\(method.name)"
				let functionRef = builder.function(named: name)
				let type = method.type.irType(in: builder) as! LLVM.ClosureType
				return LLVM.EmittedStaticMethod(
					name: name,
					receiver: receiver,
					type: type.asMethod(in: builder.context, on: structType.toLLVM(in: builder)),
					ref: functionRef
				)
			}

			print(receiver)
		default:
			()
		}

		fatalError("Could not figure out receiver for: \(expr.description)")
	}

	public func visit(_: AnalyzedParamsExpr, _: Context) throws -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedStructExpr, _ context: Context) throws -> any LLVM.EmittedValue {
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
		var emittedMethods: [LLVM.EmittedClosureValue] = []
		for (name, property) in structType.methods.sorted(by: { structType.offset(method: $0.key) < structType.offset(method: $1.key) }) {
			// TODO: Clean all this up
			let name = "\(structType.name!)_\(name)"
			var funcExpr = property.expr.cast(AnalyzedFuncExpr.self)

			// Add self to the front of the params list
			var paramsAnalyzed = funcExpr.analyzedParams

			// TODO: Need to figure out how to make the first arg here a pointer
			paramsAnalyzed.paramsAnalyzed = [AnalyzedParam(type: .struct(structType), expr: .int("self"), environment: paramsAnalyzed.environment)] + funcExpr.analyzedParams.paramsAnalyzed

//			funcExpr.name?.lexeme = name

			let methodFuncExpr = AnalyzedFuncExpr(
				type: .function(name, funcExpr.returnsAnalyzed?.type ?? .void, paramsAnalyzed, []),
				expr: funcExpr,
				analyzedParams: paramsAnalyzed,
				bodyAnalyzed: funcExpr.bodyAnalyzed,
				returnsAnalyzed: funcExpr.returnsAnalyzed,
				environment: funcExpr.environment
			)

			let emitted = try visit(methodFuncExpr, context) as! LLVM.EmittedClosureValue
			emittedMethods.append(emitted)
		}

//		let vtable = builder.vtableCreate(emittedMethods, offsets: structType.methodOffsets, name: "\(structType.name!)_methodTable")
//		let ref = structType.toLLVM(in: builder).typeRef(in: builder.context)
//		builder.saveVtable(for: ref, as: vtable)

		return LLVM.VoidValue()
	}

	public func visit(_ expr: AnalyzedDeclBlock, _ context: Context) throws -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedVarDecl, _ context: Context) throws -> any LLVM.EmittedValue {
		fatalError()
	}

	public func visit(_ expr: AnalyzedLetDecl, _ context: Context) throws -> any LLVM.EmittedValue {
		fatalError()
	}
}
