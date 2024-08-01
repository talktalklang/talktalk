//
//  Builder.swift
//  C_LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM {
	class Builder {
		private let module: Module
		let builder: LLVMBuilderRef

		public var context: Context { module.context }
		var builtins: [String: any BuiltinFunction] = [:]
		var namedTypes: [String: LLVMTypeRef] = [:]
		var verbose: Bool

		public var _ref: LLVMBuilderRef {
			builder
		}

		public var _moduleRef: LLVMModuleRef {
			module.ref
		}

		public var mainRef: LLVMValueRef {
			let ref: Int? = nil
			return withUnsafePointer(to: ref) { LLVMGenericValueRef($0) }
		}

		public init(module: Module, verbose: Bool = false) {
			self.builder = LLVMCreateBuilderInContext(module.context.ref)
			self.module = module
			self.verbose = verbose
		}

		public func global(string: String, name: String) -> LLVMValueRef {
			LLVMBuildGlobalStringPtr(builder, string, name)
		}

		public func defineGlobal(structType: StructType, name: String) -> LLVMValueRef {
			LLVMAddGlobal(module.ref, structType.typeRef(in: context), name)
		}

		// Emits binary operation IR. LHS/RHS must be the same (which isn't tough because
		// we only support int at the moment).
		public func binaryOperation<Emitted: EmittedValue>(
			_ op: BinaryOperator,
			_ lhs: Emitted,
			_ rhs: Emitted
		) -> any EmittedValue {
			let operation = LLVM.BinaryOperation<Emitted>(op: op, lhs: lhs, rhs: rhs)
			return operation.emit(in: self)
		}

		public func main(functionType: FunctionType, builtins: [any BuiltinFunction.Type]) -> any EmittedValue {
			assert(functionType.name == "main", "trying to define \(functionType.name) as main!")

			// Now do the main stuff
			let typeRef = functionType.typeRef(in: context)
			let functionRef = LLVMAddFunction(module.ref, functionType.name, typeRef)!

			let entry = LLVMAppendBasicBlock(functionRef, "entry")
			LLVMPositionBuilderAtEnd(builder, entry)

			self.builtins = builtins.reduce(into: [:]) { res, builtin in
				res[builtin.name] = builtin.init(module: module.ref, builder: self)
			}

			return LLVM.EmittedFunctionValue(type: functionType, ref: functionRef)
		}

		// Emits a @declare for a function type
		public func add(functionType: FunctionType) -> EmittedType<FunctionType> {
			return EmittedType(type: functionType, typeRef: builder)
		}

		public func define(_ functionType: FunctionType, parameterNames: [String], envStruct: CapturesStruct?, body: () throws -> Void) throws -> EmittedFunctionValue {
			let functionRef = functionRef(for: functionType)
			var functionPointerRef = functionRef

			if functionType.name.firstMatch(of: /^[A-Z]/) == nil {
				// TODO: This is a hack. We're basically trying to not emit a function malloc for methods
				functionPointerRef = createFunctionPointer(
					name: functionType.name,
					functionType: functionType,
					functionRef: functionRef,
					envStruct: envStruct
				).ref
			}

			// Get the current position we're at so we can go back there after the function is defined
			let originalBlock = LLVMGetInsertBlock(builder)
			let originalFunction = LLVMGetBasicBlockParent(originalBlock)

			// Create the entry block for the function
			let entryBlock = LLVMAppendBasicBlockInContext(context.ref, functionRef, "entry")

			for (i, name) in parameterNames.enumerated() {
				let paramRef = LLVMGetParam(functionRef, UInt32(i))
				LLVMSetValueName2(paramRef, name, name.count)
			}

			// Move the builder to our new entry block
			LLVMPositionBuilderAtEnd(builder, entryBlock)

			// Let the body block add some stuff
			try body()

			// Get the new end of the original function
			if let originalFunction {
				let returnToBlock = LLVMGetLastBasicBlock(originalFunction)
				LLVMPositionBuilderAtEnd(builder, returnToBlock)
			}

			return EmittedFunctionValue(type: functionType, ref: functionPointerRef)
		}

		public func callStatic(method: EmittedStaticMethod, with arguments: [any EmittedValue]) -> any EmittedValue {
			var arguments = arguments
			arguments.insert(method.receiver, at: 0)
			var args: [LLVMValueRef?] = arguments.map(\.ref)

			let ref = args.withUnsafeMutableBufferPointer {
				LLVMBuildCall2(
					builder,
					method.type.typeRef(in: context),
					method.ref,
					$0.baseAddress,
					UInt32($0.count),
					method.name
				)
			}!

			return method.type.returnType.emit(ref: ref)
		}

		// We want to add the receiver as the first argument for methods
		public func call(method: EmittedMethodValue, with arguments: [any EmittedValue]) -> any EmittedValue {
			let fnPtr = method.function
			let fn = LLVMBuildLoad2(
				builder,
				LLVMPointerType(method.type.typeRef(in: context), 0),
				fnPtr.ref,
				method.type.name
			)

			var arguments = arguments
			arguments.insert(method.receiver, at: 0)

			var args: [LLVMValueRef?] = arguments.map(\.ref)

			let ref = args.withUnsafeMutableBufferPointer {
				LLVMBuildCall2(
					builder,
					method.type.typeRef(in: context),
					fn,
					$0.baseAddress,
					UInt32($0.count),
					method.type.name
				)!
			}

			return switch method.type.returnType {
			case is IntType:
				EmittedIntValue(type: .i32, ref: ref)
			case let type as FunctionType:
				EmittedFunctionValue(type: type, ref: ref)
			default:
				fatalError()
			}
		}

		public func call(builtin name: String, with arguments: [any EmittedValue]) -> any EmittedValue {
			let builtin = builtins[name]
			var args: [LLVMValueRef?] = arguments.map(\.ref)
			return builtin!.call(with: &args, builder: builder)
		}

		public func instantiate(struct structType: LLVM.StructType, with args: [any EmittedValue], vtable: LLVMValueRef?) -> any EmittedValue {
			var args: [LLVMValueRef?] = args.map(\.ref)

			if let vtable {
				args.append(vtable)
			} else {}

			return args.withUnsafeMutableBufferPointer {
				let ref = LLVMConstStruct($0.baseAddress, UInt32($0.count), .zero)!
				return EmittedStructPointerValue(type: structType, ref: ref)
			}
		}

		public func call(_ fn: EmittedFunctionValue, with arguments: [any EmittedValue]) -> any EmittedValue {
			var args: [LLVMValueRef?] = arguments.map(\.ref)

			let functionPointerType = FunctionPointerType(functionType: fn.type)
			let functionRefPointer = LLVMBuildStructGEP2(
				builder,
				functionPointerType.typeRef(in: context),
				fn.ref,
				0,
				fn.type.name + "refPointer"
			)

			let functionRef = LLVMBuildLoad2(builder, LLVMPointerType(fn.type.typeRef(in: context), 0), functionRefPointer, fn.type.name)

			if let captures = fn.type.captures, !captures.types.isEmpty {
				let environmentRefPointer = LLVMBuildStructGEP2(
					builder,
					functionPointerType.typeRef(in: context),
					fn.ref,
					1,
					fn.type.name + "envPtr"
				)

				let environmentRef = LLVMBuildLoad2(builder, LLVMPointerType(captures.typeRef(in: context), 0), environmentRefPointer, "Env\(fn.type.name)")

				args.append(environmentRef)
			}

			let ref = args.withUnsafeMutableBufferPointer {
				LLVMBuildCall2(
					builder,
					fn.type.typeRef(in: context),
					functionRef,
					$0.baseAddress,
					UInt32($0.count),
					fn.type.name
				)!
			}

			return switch fn.type.returnType {
			case is IntType:
				EmittedIntValue(type: .i32, ref: ref)
			case let type as FunctionType:
				EmittedFunctionValue(type: type, ref: ref)
			default:
				fatalError()
			}
		}

		public func call(
			functionRef: LLVMValueRef,
			as functionType: FunctionType,
			with arguments: inout [LLVMValueRef?],
			returning: any IRType
		) -> any EmittedValue {
			let ref = arguments.withUnsafeMutableBufferPointer {
				LLVMBuildCall2(
					builder,
					functionType.typeRef(in: context),
					functionRef,
					$0.baseAddress,
					UInt32($0.count),
					functionType.name
				)!
			}

			return returning.emit(ref: ref)
		}

		public func capturesStruct(type: CapturesStructType, values: [(String, any StoredPointer)]) -> any EmittedValue {
			let typeRef = type.typeRef(in: context)
			let pointer = malloca(type: type, name: "")

			for (i, value) in values.enumerated() {
				log("-> setting gep for \(value.0)")
				let field = LLVMBuildStructGEP2(builder, typeRef, pointer.ref, UInt32(i), "")
				LLVMBuildStore(builder, value.1.ref, field)
			}

			return pointer
		}

		var vtables: [LLVMTypeRef: LLVMValueRef] = [:]
		public func vtable(for typeRef: LLVMTypeRef) -> LLVMValueRef? {
			vtables[typeRef]
		}

		public func vtableGetType(for ref: LLVMValueRef) -> LLVMTypeRef? {
			for (type, vtable) in vtables {
				if vtable == ref {
					return type
				}
			}

			return nil
		}

		public func saveVtable(for typeRef: LLVMTypeRef, as vtable: LLVMValueRef) {
			vtables[typeRef] = vtable
		}

		public func vtableCreate(_ array: [EmittedFunctionValue], offsets: [String: Int], name: String) -> LLVMValueRef {
			if let existing = LLVMGetNamedGlobal(module.ref, name) {
				LLVMDumpValue(existing)
				fatalError("global already exists with name: \(name)! ")
			}

			var types: [LLVMTypeRef?] = array.map {
				LLVMPointerType($0.type.typeRef(in: context), 0)
			}

			let vtableStructTypeRef = LLVMStructCreateNamed(context.ref, name)

			types.withUnsafeMutableBufferPointer {
				LLVMStructSetBody(
					vtableStructTypeRef,
					$0.baseAddress,
					UInt32($0.count),
					LLVMBool(1)
				)
			}

			let vtable = LLVMAddGlobal(module.ref, vtableStructTypeRef, name)

			var fns: [LLVMValueRef?] = []
			for fn in array {
				fns.append(fn.ref)
			}

			let s = LLVMConstNamedStruct(vtableStructTypeRef, &fns, UInt32(fns.count))
			LLVMSetInitializer(vtable, s)

			vtables[vtableStructTypeRef!] = vtable!

			return vtable!
		}

		public func vtable(named: String) -> LLVMValueRef {
			LLVMGetNamedGlobal(module.ref, named)
		}

		public func vtableLookup(_ vtable: LLVMValueRef, capacity: Int, at index: Int, as type: LLVM.FunctionType) -> EmittedFunctionValue {
			let vtable: LLVMValueRef? = vtable

			let fnRef = LLVMBuildStructGEP2(
				builder,
				vtableGetType(for: vtable!),
				vtable,
				UInt32(index),
				"gep_\(type.name)"
			)!

			return EmittedFunctionValue(type: type, ref: fnRef)
		}

		public func malloca(type: any LLVM.IRType, name: String) -> any StoredPointer {
			let malloca = if let functionType = type as? FunctionType {
				{
					// Get the function
					let fn = LLVMGetNamedFunction(module.ref, functionType.name)!

					// Get a pointer type to the function
					let functionPointerType = LLVMPointerType(LLVMTypeOf(fn), 0)

					// Allocate the space for the function pointer
					let malloca = inEntry {
						LLVMBuildMalloc(builder, functionPointerType, name)!
					}

					return malloca
				}()
			} else {
				inEntry { LLVMBuildMalloc(builder, type.typeRef(in: context), name)! }
			}

			// Return the stack value
			switch type {
			case let type as LLVM.FunctionType:
				return HeapValue<LLVM.FunctionType>(type: type, ref: malloca)
			case let type as LLVM.IntType:
				return HeapValue<LLVM.IntType>(type: type, ref: malloca)
			case let type as LLVM.StructType:
				return HeapValue<LLVM.StructType>(type: type, ref: malloca)
			case let type as LLVM.CapturesStructType:
				return HeapValue<LLVM.CapturesStructType>(type: type, ref: malloca)
			case let type as LLVM.ArrayType:
				return HeapValue<LLVM.ArrayType>(type: type, ref: malloca)
			default:
				fatalError()
			}
		}

		public func alloca(type: any LLVM.IRType, name: String) -> any StoredPointer {
			let alloca = if let functionType = type as? LLVM.FunctionType {
				{
					let fn = functionRef(for: functionType)

					// Get a pointer type to the function
					let functionPointerType = LLVMPointerType(LLVMTypeOf(fn), 0)

					// Allocate the space for the function pointer
					let alloca = inEntry {
						LLVMBuildAlloca(builder, functionPointerType, name)!
					}

					return alloca
				}()
			} else {
				inEntry { LLVMBuildAlloca(builder, type.typeRef(in: context), name)! }
			}

			// Return the stack value
			switch type {
			case let type as LLVM.FunctionType:
				return StackValue<LLVM.FunctionType>(type: type, ref: alloca)
			case let type as LLVM.IntType:
				return StackValue<LLVM.IntType>(type: type, ref: alloca)
			case let type as LLVM.StructType:
				return StackValue<LLVM.StructType>(type: type, ref: alloca)
			case let type as LLVM.ArrayType:
				return StackValue<LLVM.ArrayType>(type: type, ref: alloca)
			default:
				fatalError()
			}
		}

		public func namedStruct(name: String, types: [any IRType]) -> LLVMTypeRef {
			if let existing = namedTypes[name] {
				return existing
			}

			let ref = LLVMStructCreateNamed(context.ref, name)
			var types: [LLVMTypeRef?] = types.map { $0.typeRef(in: context) }

			types.withUnsafeMutableBufferPointer {
				LLVMStructSetBody(ref, $0.baseAddress, UInt32($0.count), .zero)
			}

			namedTypes[name] = ref

			return ref!
		}

		public func store<Emitted: EmittedValue>(heapValue: Emitted, name: String = "") -> HeapValue<Emitted.T> {
			if let function = heapValue.type as? FunctionType {
				// Get the function
				let fn = LLVMGetNamedFunction(module.ref, function.name)!

				// Get a pointer type to the function
				let functionPointerType = LLVMPointerType(LLVMTypeOf(fn), 0)

				// Allocate the space for the function pointer
				let malloca = inEntry {
					LLVMBuildMalloc(builder, functionPointerType, name)!
				}

				// Actually store the function pointer into the spot
				_ = LLVMBuildStore(builder, fn, malloca)!

				// Return the stack value
				return HeapValue<Emitted.T>(type: heapValue.type, ref: malloca)
			} else {
				let malloca = inEntry { LLVMBuildAlloca(builder, heapValue.type.typeRef(in: context), name)! }
				_ = LLVMBuildStore(builder, heapValue.ref, malloca)!
				return HeapValue<Emitted.T>(type: heapValue.type, ref: malloca)
			}
		}

		public func store(_ value: any EmittedValue, to pointer: any StoredPointer) -> any StoredPointer {
			LLVMBuildStore(builder, value.ref, pointer.ref)
			return pointer
		}

		public func store(_ value: LLVMValueRef, in array: inout LLVMValueRef?, at offset: Int, type: any IRType) {
			_ = withUnsafeMutablePointer(to: &array) {
				LLVMBuildGEP2(builder, type.typeRef(in: context), $0.pointee, $0, UInt32(offset), "arrgep")
			}
		}

		public func store(capture value: any EmittedValue, at index: Int, as envStructType: CapturesStructType) {
			let parameterCount = LLVMCountParams(currentFunction)

			// Get the env pointer
			let envParam = LLVMGetParam(currentFunction, parameterCount - 1)!

			// Load the env
			let env = LLVMBuildLoad2(builder, LLVMPointerType(envStructType.typeRef(in: context), 0), envParam, "envTmp")

			// Get the pointer to the captured value out of the env
			let ptr = LLVMBuildStructGEP2(
				builder,
				envStructType.typeRef(in: context),
				env,
				UInt32(index),
				"capture_\(index)Ptr_"
			)

			LLVMBuildStore(builder, value.ref, ptr)
		}

		// TODO: Move these to top of basic block
		public func store<Emitted: EmittedValue>(stackValue: Emitted, name: String = "") -> StackValue<Emitted.T> {
			if let function = stackValue.type as? FunctionType {
				// Get the function
				let fn = LLVMGetNamedFunction(module.ref, function.name)!

				// Get a pointer type to the function
				let functionPointerType = LLVMPointerType(LLVMTypeOf(fn), 0)

				// Allocate the space for the function pointer
				let alloca = inEntry {
					LLVMBuildAlloca(builder, functionPointerType, name)!
				}

				// Actually store the function pointer into the spot
				_ = LLVMBuildStore(builder, fn, alloca)!

				// Return the stack value
				return StackValue<Emitted.T>(type: stackValue.type, ref: alloca)
			} else {
				let alloca = inEntry { LLVMBuildAlloca(builder, stackValue.type.typeRef(in: context), name)! }
				_ = LLVMBuildStore(builder, stackValue.ref, alloca)!
				return StackValue<Emitted.T>(type: stackValue.type, ref: alloca)
			}
		}

		public func load(from array: EmittedArrayValue, at index: Int, as type: any IRType) -> any EmittedValue {
			var array: LLVMValueRef? = array.ref

			let ptr = withUnsafeMutablePointer(to: &array) {
				LLVMBuildGEP2(builder, type.typeRef(in: context), $0.pointee, $0, UInt32(index), "arrgep")
			}

			let ref = LLVMBuildLoad2(builder, type.typeRef(in: context), ptr, "arrload")!
			return type.emit(ref: ref)
		}

		public func load(from structPointer: EmittedStructPointerValue, index: Int, as type: any IRType, name: String) -> any EmittedValue {
			let ptr = LLVMBuildStructGEP2(
				builder,
				structPointer.type.typeRef(in: context),
				structPointer.ref,
				UInt32(index),
				name
			)

			let ref = LLVMBuildLoad2(builder, type.typeRef(in: context), ptr, "loaded_\(name)")!
			return type.emit(ref: ref)
		}

		public func load(parameter: Int) -> any EmittedValue {
			let ref = LLVMGetParam(currentFunction, UInt32(parameter))!
			return EmittedIntValue(type: .i32, ref: ref)
		}

		// When loading captured values, we need to go to the environment param passed
		// as the last argument.
		public func load(capture index: Int, envStructType: CapturesStructType) -> any EmittedValue {
			let paramCount = LLVMCountParams(currentFunction)

			// Get the env pointer
			let envParam = LLVMGetParam(currentFunction, paramCount - 1)!

			// Get the value out of the env
			let ptr = LLVMBuildStructGEP2(
				builder,
				envStructType.typeRef(in: context),
				envParam,
				UInt32(index),
				"capture_\(index)Ptr_"
			)

			let returnType = envStructType.types[index]
			let returningPtr = LLVMBuildLoad2(builder, LLVMPointerType(returnType.typeRef(in: context), 0), ptr, "capture_\(index)ReturningPtr_")!
			let returning = LLVMBuildLoad2(builder, returnType.typeRef(in: context), returningPtr, "capture_\(index)_")!
			return switch returnType {
			case let type as LLVM.IntType:
				EmittedIntValue(type: type, ref: returning)
			case let type as LLVM.FunctionType:
				EmittedFunctionValue(type: type, ref: returning)
			default:
				fatalError()
			}
		}

		public func load(builtin name: String, as type: any IRType) -> any EmittedValue {
			switch type {
			case let type as LLVM.FunctionType:
				let fn = LLVMGetNamedFunction(module.ref, name)!
				return EmittedFunctionValue(type: type, ref: fn)
			default:
				fatalError("cannot load builtin: \(name)")
			}
		}

		public func load(pointer: LLVMValueRef, as type: any IRType, name: String = "") -> any EmittedValue {
			let ref = LLVMBuildLoad2(builder, type.typeRef(in: context), pointer, name)!
			return type.emit(ref: ref)
		}

		public func load(pointer: any StoredPointer, name: String = "") -> any EmittedValue {
			switch pointer.type {
			case let type as IntType:
				let ref = LLVMBuildLoad2(builder, pointer.type.typeRef(in: context), pointer.ref, name)!
				return EmittedIntValue(type: type, ref: ref)
			case let type as FunctionType:
				// If it's a function we've stored a pointer to it (see store), so we need to change
				// the type to a pointer.
				let pointerType = LLVMPointerType(pointer.type.typeRef(in: context), 0)
				let ref = LLVMBuildLoad2(builder, pointerType, pointer.ref, name)!
				return EmittedFunctionValue(type: type, ref: ref)
			case let type as StructType:
//				let pointerType = LLVMPointerType(pointer.type.typeRef(in: context), 0)
//				let ref = LLVMBuildLoad2(builder, pointerType, pointer.ref, name)!
				return EmittedStructPointerValue(type: type, ref: pointer.ref)
			default:
				fatalError()
			}
		}

		public func function(named name: String) -> LLVMValueRef {
			LLVMGetNamedFunction(module.ref, name)
		}

		public func emit(constant: Constant<some IRValue, some Any>) -> any EmittedValue {
			let ref = constant.valueRef(in: context)

			switch constant.type {
			case let type as IntType:
				return EmittedIntValue(type: type, ref: ref)
			default:
				fatalError()
			}
		}

		public func emit(return value: any EmittedValue) -> any IRValue {
			_ = LLVMBuildRet(
				builder,
				value.ref
			)!

			return value
		}

		public func emit(return value: RawValue) -> any IRValue {
			let ref = LLVMBuildRet(
				builder,
				value.ref
			)!

			return RawValue(ref: ref)
		}

		public func emit(return stackValue: StackValue<some IRValue>) -> any IRValue {
			let ref = LLVMBuildRet(
				builder,
				stackValue.ref
			)!

			switch stackValue.type {
			case let value as IntType:
				return EmittedIntValue(type: value, ref: ref)
			default:
				fatalError("Not yet")
			}
		}

		public func emitVoidReturn() {
			LLVMBuildRetVoid(builder)
		}

		public func dump() {
			module.dump()
		}

		// MARK: Helpers

		private func createFunctionPointer(
			name: String,
			functionType: FunctionType,
			functionRef: LLVMValueRef,
			envStruct: CapturesStruct?
		) -> any StoredPointer {
			let functionPointerType = LLVM.TypePointer(type: functionType)

			let types: [any IRType] = if let envStruct {
				[functionPointerType, envStruct.type]
			} else {
				[functionPointerType]
			}

			let structType = CapturesStructType(name: name, types: types)
			let structTypeRef = structType.typeRef(in: context)
			let pointer = malloca(type: structType, name: name)

			log("-> setting function ref for pointer: \(name)")
			let field = LLVMBuildStructGEP2(builder, structTypeRef, pointer.ref, UInt32(0), "")
			LLVMBuildStore(builder, functionRef, field)

			if let envStruct {
				log("-> setting environment ref for pointer: \(name)")
				let field = LLVMBuildStructGEP2(builder, structTypeRef, pointer.ref, UInt32(1), "")
				LLVMBuildStore(builder, envStruct.ref, field)
			}

			LLVMVerifyFunction(functionRef, LLVMPrintMessageAction)

			return pointer
		}

		private func functionRef(for functionType: FunctionType) -> LLVMValueRef {
			// Get the function
			if let fn = LLVMGetNamedFunction(module.ref, functionType.name) {
				return fn
			} else {
				return LLVMAddFunction(module.ref, functionType.name, functionType.typeRef(in: context))
			}
		}

		private var currentFunction: LLVMValueRef {
			let currentBlock = LLVMGetInsertBlock(builder)
			return LLVMGetBasicBlockParent(currentBlock)
		}

		// Emits the block into the entry block of the current function
		func inEntry<T>(perform: () -> T) -> T {
			let currentBlock = LLVMGetInsertBlock(builder)
			let function = LLVMGetBasicBlockParent(currentBlock)
			let entryBlock = LLVMGetEntryBasicBlock(function)

			if let firstInstruction = LLVMGetFirstInstruction(entryBlock) {
				LLVMPositionBuilderBefore(builder, firstInstruction)
			} else {
				LLVMPositionBuilderAtEnd(builder, entryBlock)
			}

			let result = perform()

			LLVMPositionBuilderAtEnd(builder, currentBlock)
			return result
		}

		func log(_ message: String) {
			if verbose {
				print(message)
			}
		}
	}
}
