import C_LLVM
import TalkTalkSyntax
import TalkTalkTyper

public struct CompilerABTVisitor: ABTVisitor {
	let emitter: LLVM.Emitter
	var context: LLVM.Context { emitter.builder.module.context }

	// symbol maps
	var heapValues: HeapValues { emitter.currentFunction.environment.heapValues }
	var stackValues: StackValues { emitter.currentFunction.environment.stackValues }

	init(module: LLVM.Module) {
		self.emitter = LLVM.Emitter(module: module)
	}

	public func visit(_ node: Program) -> any LLVM.IR {
		returnLast(in: node.declarations)
	}

	public func visit(_ node: Block) -> any LLVM.IR {
		returnLast(in: node.children)
	}

	public func visit(_ node: Literal) -> any LLVM.IR {
		let res = node.value.get()

		return res
	}

	public func visit(_ node: Function) -> any LLVM.IR {
		// Get the binding of this function in its parent scope
		// so we can see if it goes on the stack or heap
		let binding = node.scope.parent!.binding(for: node)!

		// Create a new Environment for this function.
		let environment = Environment(
			name: node.name,
			parent: emitter.currentFunction.environment,
			scope: node.scope,
			emitter: emitter
		)

		// If this function captures values, we need to capture them
		// at function definition time (not call time) so do that here.
		let capturesHeapValue = environment.emitCaptures()

		// TODO: validate we're not redeclaring the same function
		let type = node.prototype.toLLVM(in: context, with: environment)

		// Stash the old function so we can restore it after emitting this one
		let oldFunction = emitter.currentFunction

		// Build a new function prototype
		let newFunction = emitter.builder.addFunction(
			named: node.name,
			type: type,
			environment: environment
		)

		// Set is as the current function
		emitter.currentFunction = newFunction

		// Emit the entry basic block for the new function
		let entry = LLVMAppendBasicBlockInContext(
			emitter.builder.module.context.ref,
			newFunction.ref,
			"entry"
		)

		// Move the builder to start emitting into the entry block
		LLVMPositionBuilderAtEnd(emitter.builder.ref, entry)

		// Now that we're in the new function, we want to grab the env out of the
		// args. It should always be the last item.
		environment.environmentParam = LLVMGetParam(newFunction.ref, UInt32(node.prototype.parameters.count))

		// Emit allocas/mallocs for the function. We do this first so that they're
		// in the entry block which makes stuff easier for the optimizer.
		environment.emitEntry()

		// Stash the environment on the function... this might not be right? I think
		// we actually want to pass this as an arg at the call site?
		newFunction.environment = environment

		// Emit allocas for the parameters
		// TODO: Where do we actually set these values?
		_ = visit(node.prototype.parameters)

		// Call returnLast, which goes through each of the body's children, preserving
		// the last return value so it can be emitted. If there isn't one, we can
		// just emit a void return.
		if let retval = returnLast(in: node.body.children) as? any LLVM.IRValue {
			emitter.emitReturn(retval)
		} else {
			emitter.emitReturn(nil)
		}

		// Restore the old function as our current function
		emitter.currentFunction = oldFunction

		// Move the builder back to the end of our old function
		let oldBlock = LLVMGetLastBasicBlock(oldFunction.ref)
		LLVMPositionBuilderAtEnd(emitter.builder.ref, oldBlock)

		// If this function escapes its enclosing function, save a pointer
		// to it to the heap and return that instead of the function itself
		if binding.isEscaping {
			let heapValue = emitter.malloc(
				newFunction.type,
				name: node.name
			)

			heapValue.store(newFunction, in: emitter.builder)
			heapValues[node.name] = heapValue

			return heapValue
		}

		return newFunction
	}

	public func visit(_ node: ParameterList) -> any LLVM.IR {
		for (name, binding) in node.list {
			let type = binding.type.toLLVM(in: context)
			stackValues[name] = emitter.alloca(type, name: name)
		}

		return .void(context)
	}

	public func visit(_ node: VoidNode) -> any LLVM.IR {
		.void(context)
	}

	public func visit(_ node: IfExpression) -> any LLVM.IR {
		.void(context)
	}

	public func visit(_ node: OperatorNode) -> any LLVM.IR {
		switch node.syntax.cast(BinaryOperatorSyntax.self).kind {
		case .plus:
			LLVMAdd
		default:
			.void(context)
		}
	}

	public func visit(_ node: AssignmentExpression) -> any LLVM.IR {
		let location = node.lhs.accept(self) as! any LLVM.IRValue
		let value = node.rhs.accept(self) as! any LLVM.IRValue

		emitter.store(value, in: location)
		return value
	}

	public func visit(_ node: TypeDeclaration) -> any LLVM.IR {
		.void(context)
	}

	public func visit(_ node: VarLetDeclaration) -> any LLVM.IR {
		// If we have an expression as part of the decl, we can store that right
		// away
		if let expression = node.expression {
			guard let value = expression.accept(self) as? any LLVM.IRValue else {
				fatalError("cannot store non IRValue")
			}

			if let heapValue = heapValues[node.name] {
				emitter.store(value, in: heapValue)
				return heapValue
			} else {
				let type = node.type.toLLVM(in: context)
				stackValues[node.name] = emitter.alloca(type, name: node.name)
				stackValues[node.name]?.store(value, in: emitter.builder)

				return stackValues[node.name]!
			}
		}

		return .void(context)
	}

	public func visit(_ node: BinaryOpExpression) -> any LLVM.IR {
		let lhs = node.lhs.accept(self) as! any LLVM.IRValue
		let rhs = node.rhs.accept(self) as! any LLVM.IRValue

		let op = visit(node.op)

		let ref = emitter.emit(
			binaryOp: op.asLLVM(),
			lhs: lhs,
			rhs: rhs
		)

		switch node.type {
		case is IntType:
			return LLVM.IntValue(ref: ref)
		default:
			fatalError("Not yet")
		}
	}

	public func visit(_ node: TODONode) -> any LLVM.IR {
		.void(context)
	}

	public func visit(_ node: UnknownSemanticNode) -> any LLVM.IR {
		fatalError("Unknown node: \(node.description)")
	}

	public func visit(_ node: CallExpression) -> any LLVM.IR {
		switch node.callee {
		case let callee as Function:
			return emitter.callFunction(
				named: callee.name,
				returning: callee.prototype.returns.toLLVM(in: context),
				with: visit(node.arguments).asLLVM(),
				environment: emitter.currentFunction.environment
			)
		case let callee as VarExpression:
			if let function = node.scope.lookup(identifier: callee.name)?.node.as(Function.self) {
				return emitter.callFunction(
					named: function.name,
					returning: function.prototype.returns.toLLVM(in: context),
					with: visit(node.arguments).asLLVM(),
					environment: emitter.currentFunction.environment
				)
			} else {
				// We've got a variable that's a pointer to a function so we need to resolve
				// it real quick.
				let type = node.scope.lookup(identifier: callee.name)!.type as! FunctionType
				let stackValue = emitter.currentFunction.environment.lookup(identifier: callee.name) as! LLVM.StackValue

				let functionRef = LLVMBuildLoad2(
					emitter.builder.ref,
					LLVM.PointerType(pointee: type.toLLVM()).ref,
					stackValue.ref,
					callee.name
				)!

				let args: [any LLVM.IRValue] = visit(node.arguments).asLLVM()
				var arguments: [LLVMValueRef?] = args.map(\.ref)

				return arguments.withUnsafeMutableBufferPointer {
					let ref = LLVMBuildCall2(
						emitter.builder.ref,
						type.toLLVM().ref,
						functionRef,
						$0.baseAddress,
						UInt32($0.count),
						callee.name
					)!

					switch type.returns {
					case is IntType:
						return LLVM.IntValue(ref: ref)
					case is FunctionType:
						return LLVM.Pointer(
							type: .init(pointee: type.returns.toLLVM()),
							ref: ref
						)
					default:
						fatalError("nope")
					}
				}
			}
		default:

			fatalError("I dont' know what to do with this callee \(node.callee)")
		}
	}

	public func visit(_ node: ArgumentList) -> any LLVM.IR {
		let result: [any LLVM.IR] = node.list.map { _, node in
			node.accept(self) as any LLVM.IR
		}

		return result
	}

	public func visit(_ node: VarExpression) -> any LLVM.IR {
		let value = emitter.currentFunction.environment.lookup(identifier: node.name)
		switch value {
		case let heapValue as LLVM.HeapValue:
			return emitter.load(heapValue: heapValue, as: node.name)
		case let stackValue as LLVM.StackValue:
			return emitter.load(stackValue: stackValue, as: node.name)
		default:
			// Get it from the environment
			let type = if node.type is FunctionType {
				LLVM.PointerType(pointee: node.type.toLLVM(in: context))
			} else {
				node.type.toLLVM(in: context)
			}

			return switch node.type {
			case is FunctionType:
				LLVM.Pointer(type: .init(pointee: type), ref: value.ref)
			case is IntType:
				LLVM.Pointer(type: .init(pointee: type), ref: value.ref)
			default:
				fatalError("not yet")
			}
		}
	}

	// MARK: Helpers

	private func returnLast(in nodes: [any SemanticNode]) -> any LLVM.IR {
		var lastReturn: (any LLVM.IR)?
		for node in nodes {
			lastReturn = node.accept(self)
		}
		return lastReturn!
	}
}
