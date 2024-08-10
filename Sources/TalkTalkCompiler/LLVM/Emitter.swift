import C_LLVM

extension LLVM {
	class Emitter {
		let builder: LLVM.Builder
		var currentFunction: Function

		init(module: Module) {
			builder = LLVM.Builder(module: module)

			let mainType = LLVM.FunctionType(
				context: .global,
				returning: .i32(module.context),
				parameters: [],
				isVarArg: false
			)

			// Let's get print goin
			var printArgs = [
				LLVMPointerType(
					LLVMInt8TypeInContext(
						builder.module.context.ref
					),
					0
				)
			]

			let printfType = printArgs.withUnsafeMutableBufferPointer {
				LLVMFunctionType(
					LLVMPointerType(
						LLVMInt8TypeInContext(
							module.context.ref
						),
						0
					),
					$0.baseAddress,
					UInt32(1),
					LLVMBool(1)
				)
			}
			_ = LLVMAddFunction(module.ref, "printf", printfType)

			let mainEnvironment = Environment(
				name: "main",
				parent: nil,
				scope: .init(),
				emitter: nil
			)

			let function = builder.addFunction(named: "xmain", type: mainType, environment: mainEnvironment)
			let blockRef = LLVMAppendBasicBlockInContext(
				builder.module.context.ref,
				function.ref,
				"entry"
			)

			currentFunction = function

			LLVMPositionBuilderAtEnd(builder.ref, blockRef)

			mainEnvironment.emitter = self
		}

		func call(
			closure: Closure,
			with arguments: [any IRValue],
			environment: Environment
		) -> any LLVM.IRValue {
			let argumentsCount = arguments.count
			let function = closure.function
			let returning = closure.functionType.returning
			let environment = closure.environment

			var arguments: [LLVMValueRef?] = arguments.map(\.ref)
			arguments.append(environment.environmentParam)

			let ref = arguments.withUnsafeMutableBufferPointer {
				LLVMBuildCall2(
					builder.ref,
					returning.ref,
					function.ref,
					$0.baseAddress,
					UInt32(argumentsCount),
					"call_\(closure.name)"
				)
			}!

			return switch returning {
			case is LLVM.IntType:
				IntValue(ref: ref)
			case is LLVM.FunctionType:
				Pointer(type: PointerType(pointee: returning), ref: ref)
			default:
				fatalError("unhandled")
			}
		}

		func callFunction(
			pointer functionRef: LLVM.Function,
			with arguments: [any IRValue],
			environment: Environment
		) -> any LLVM.IRValue {
			var arguments: [LLVMValueRef?] = arguments.map(\.ref)
			let argumentsCount = arguments.count

			arguments.append(environment.environmentParam)

			let ref = arguments.withUnsafeMutableBufferPointer {
				LLVMBuildCall2(
					builder.ref,
					functionRef.type.returning.ref,
					functionRef.ref,
					$0.baseAddress,
					UInt32(argumentsCount),
					"call\(functionRef.ref)"
				)
			}!

			return switch functionRef.type.returning {
			case is LLVM.IntType:
				IntValue(ref: ref)
			case is LLVM.FunctionType:
				Pointer(type: PointerType(pointee: functionRef.type.returning), ref: ref)
			default:
				fatalError("unhandled")
			}
		}

		func load(stackValue: StackValue, as name: String) -> any LLVM.IRValue {
			var type = stackValue.type

			if type is LLVM.FunctionType {
				type = LLVM.PointerType(pointee: type)
			}

			let ref = LLVMBuildLoad2(builder.ref, stackValue.type.ref, stackValue.ref, name)!
			return Pointer(type: .init(pointee: type), ref: ref)
		}

		func load(pointer: Pointer, as name: String) -> any LLVM.IRValue {
			let type = pointer.type.pointee
			let ref = LLVMBuildLoad2(builder.ref, type.ref, pointer.ref, name)!
			return switch type {
			case is LLVM.IntType:
				IntValue(ref: ref)
			default:
				fatalError("TODO")
			}
		}

		func load(heapValue: HeapValue, as name: String) -> any LLVM.IRValue {
			var type = heapValue.type
			let ref = LLVMBuildLoad2(builder.ref, heapValue.type.ref, heapValue.ref, name)!
			return Pointer(type: .init(pointee: type), ref: ref)
		}

		// Emit the alloca instruction, converting the type to a function pointer if necessary
		func alloca(_ type: any LLVM.IRType, name: String) -> LLVM.StackValue {
			var type = type

			if type is LLVM.FunctionType {
				type = LLVM.PointerType(pointee: type)
			}

			let ref = LLVMBuildAlloca(
				builder.ref,
				type.ref,
				name
			)!

			return LLVM.StackValue(ref: ref, type: type)
		}

		// Emit the malloc instruction, converting the type to a function pointer if necessary
		func malloc(_ type: any LLVM.IRType, name: String, with value: (any LLVM.IRValue)? = nil) -> LLVM.HeapValue {
			var type = type

			if type is LLVM.FunctionType {
				type = LLVM.PointerType(pointee: type)
			}

			let ref = LLVMBuildMalloc(
				builder.ref,
				type.ref,
				name
			)!

			if let value {
				LLVMBuildStore(
					builder.ref,
					value.ref,
					ref
				)
			}

			return LLVM.HeapValue(ref: ref, type: type)
		}

		func store(_ value: any LLVM.IRValue, in location: any LLVM.IRValue) {
			LLVMBuildStore(builder.ref, value.ref, location.ref)
		}

		func store(_ value: any LLVM.IRValue, in location: LLVMValueRef) {
			LLVMBuildStore(builder.ref, value.ref, location)
		}

		func store(_ value: any LLVM.IRValue, in stackValue: LLVM.StackValue) {
			LLVMBuildStore(builder.ref, value.ref, stackValue.ref)
		}

		func store(_ value: any LLVM.IRValue, in heapValue: LLVM.HeapValue) {
			LLVMBuildStore(builder.ref, value.ref, heapValue.ref)
		}

		func emit(
			binaryOp: LLVMOpcode,
			lhs: any IRValue,
			rhs: any IRValue,
			name: String = ""
		) -> LLVMValueRef {
			var lhs = lhs
			if let ptr = lhs as? HeapValue {
				lhs = load(heapValue: ptr, as: "tmp")
			} else if let ptr = lhs as? StackValue, ptr.type is PointerType {
				lhs = load(stackValue: ptr, as: "tmp")
			} else if let ptr = lhs as? Pointer {
				lhs = load(pointer: ptr, as: "tmp")
			}

			var rhs = rhs
			if let ptr = rhs as? HeapValue {
				rhs = load(heapValue: ptr, as: "tmp")
			} else if let ptr = rhs as? StackValue, ptr.type is PointerType {
				rhs = load(stackValue: ptr, as: "tmp")
			}

			return LLVMBuildBinOp(
				builder.ref,
				binaryOp,
				lhs.ref,
				rhs.ref,
				name
			)
		}

		func emit(
			functionType: FunctionType,
			named name: String,
			environment: Environment,
			perform: (LLVM.Function) -> Void
		) -> LLVM.Function {
			// Stash the old function so we can restore it after emitting this one
			let oldFunction = currentFunction

			// Build a new function prototype
			let newFunction = builder.addFunction(named: name, type: functionType, environment: environment)
			// Set is as the current function
			currentFunction = newFunction

			// Emit the entry basic block for the new function
			let entry = LLVMAppendBasicBlockInContext(
				builder.module.context.ref,
				newFunction.ref,
				"entry"
			)

			// Move the builder to start emitting into the entry block
			LLVMPositionBuilderAtEnd(builder.ref, entry)

			// Emit more stuff from the perform callback
			perform(newFunction)

			// Restore the old function as our current function
			currentFunction = oldFunction

			// Move the builder back to the end of our old function
			let oldBlock = LLVMGetLastBasicBlock(oldFunction.ref)
			LLVMPositionBuilderAtEnd(builder.ref, oldBlock)

			// Return the new function so the enclosing function can save
			// a pointer to it if it's used as a return value
			return newFunction
		}

		func emitReturn(_ val: (any LLVM.IRValue)? = nil) {
			guard let val else {
				LLVMBuildRetVoid(builder.ref)
				return
			}

			if let ptr = val as? Pointer, !(ptr.type.pointee is LLVM.FunctionType) {
				LLVMBuildRet(
					builder.ref,
					LLVMBuildLoad2(
						builder.ref,
						ptr.type.pointee.ref,
						ptr.ref,
						"rettmp"
					)
				)

				return
			}

			if let ptr = val as? HeapValue {
				LLVMBuildRet(
					builder.ref,
					LLVMBuildLoad2(
						builder.ref,
						ptr.type.ref,
						ptr.ref,
						"rettmp"
					)
				)

				return
			}

			LLVMBuildRet(builder.ref, val.ref)
		}

		func emitVoidReturn() {
			LLVMBuildRetVoid(builder.ref)
		}
	}
}
