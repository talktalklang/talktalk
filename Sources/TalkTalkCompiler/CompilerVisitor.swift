//
//  CompilerVisitor.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
import C_LLVM
import TalkTalkSyntax
import TalkTalkTyper

class CompilerVisitor: ASTVisitor {
	var bindings: Bindings
	var builder: LLVM.Builder
	var module: LLVM.Module
	var currentFunction: LLVM.Function
	var heapValues: [String: LLVM.HeapValue] = [:]

	init(bindings: Bindings, builder: LLVM.Builder, module: LLVM.Module) {
		self.bindings = bindings
		self.builder = builder
		self.module = module

		let mainType = LLVM.FunctionType(
			context: .global,
			returning: .i32(.global),
			parameters: [],
			isVarArg: false
		)

		// Let's get print goin
		var printArgs = [LLVMPointerType(LLVMInt8TypeInContext(module.context.ref), 0)]
		let printfType = printArgs.withUnsafeMutableBufferPointer {
			LLVMFunctionType(
				LLVMPointerType(
					LLVMInt8TypeInContext(module.context.ref), 0
				),
				$0.baseAddress,
				UInt32(1),
				LLVMBool(1)
			)
		}
		_ = LLVMAddFunction(module.ref, "printf", printfType)

		let function = builder.addFunction(named: "main", mainType)!
		let blockRef = LLVMAppendBasicBlockInContext(module.context.ref, function.ref, "entry")
		currentFunction = function

		LLVMPositionBuilderAtEnd(builder.ref, blockRef)
	}

	func map(_ type: ValueType) -> any LLVM.IRType {
		switch type {
		case .int:
			return .i32()
		case .void:
			return .void()
		case .function(type):
			return map(type.returns?.value ?? .void)
		default:
			fatalError()
		}
	}

	func resolveFunction(named name: String, in module: LLVM.Module) -> LLVM.Function? {
		if let named = module.function(named: name) {
			return named
		}

		if let captured = heapValues[name], let functionType = captured.type as? LLVM.FunctionType {
			return LLVM.Function(type: functionType, ref: captured.ref)
		}

		return nil
	}

	// MARK: Visitors

	func visit(_ node: ProgramSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		var lastReturn: LLVM.IRValueRef?
		for decl in node.decls {
			lastReturn = visit(decl, context: module)
		}

		if case let .value(lastReturn) = lastReturn {
			LLVMBuildRet(builder.ref, lastReturn.ref)
		}

		return .void()
	}

	func visit(_ node: FunctionDeclSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		let typedef = bindings.type(for: node.name)!
		let ret = typedef.type.returns?.value
		let returnType: any LLVM.IRType = map(ret!)

		let parameters: [(String, any LLVM.IRType)] = node.parameters.parameters.reduce(into: []) { res, parameter in
			switch bindings.type(for: parameter)?.type {
			case .int: res.append((parameter.lexeme, .i32()))
			default:
				fatalError()
			}
		}

		let functionType = LLVM.FunctionType(
			context: module.context,
			returning: returnType,
			parameters: parameters,
			isVarArg: false // We don't support var args yet
		)

		// TODO: validate we're not redeclaring the same function
		let function = builder.addFunction(named: node.name.lexeme, functionType)!

		for capture in typedef.environment!.captures {
			let type = capture.value.value.llvmType(in: module.context, bindings: bindings)

			// TODO: !! handle freeing this !!
			// TODO: also check to see if it's already allocated
			let ptr = LLVMBuildMalloc(
				builder.ref,
				type.ref,
				capture.key
			)!

			heapValues[capture.key] = LLVM.HeapValue(ref: ptr, type: type)
		}

		//
		let oldFunction = currentFunction
		currentFunction = function

		let entry = LLVMAppendBasicBlockInContext(module.context.ref, function.ref, "entry")
		LLVMPositionBuilderAtEnd(builder.ref, entry)

		for parameter in node.parameters.parameters {
			function.parameters[parameter.lexeme] = .declared
		}

		_ = visit(node.body, context: module)

		currentFunction = oldFunction
		let block = LLVMGetLastBasicBlock(oldFunction.ref)
		LLVMPositionBuilderAtEnd(builder.ref, block)

		oldFunction.locals[node.name.lexeme] = .defined(function.ref)
		return .value(function.ref)
	}

	func visit(_ node: VarDeclSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		let type = bindings.type(for: node)!.llvmType(in: builder.module.context, bindings: bindings)
		let value = currentFunction.allocate(name: node.variable.lexeme, for: type, in: builder)

		currentFunction.locals[node.variable.lexeme] = .allocated(value)

		if let expr = node.expr {
			value.store(visit(expr, context: module).unwrap(), in: builder)
		}

		return .void()
	}

	func visit(_ node: LetDeclSyntax, context: LLVM.Module) -> LLVM.IRValueRef {
		if let expr = node.expr {
			currentFunction.locals[node.variable.lexeme] = .defined(
				visit(expr, context: context).unwrap()!
			)
		} else {
			currentFunction.locals[node.variable.lexeme] = .declared
		}

		return .void()
	}

	func visit(_: ClassDeclSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: InitDeclSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: PropertyDeclSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_ node: ExprStmtSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		visit(node.expr, context: module)
	}

	func visit(_ node: BlockStmtSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		var lastReturn: LLVM.IRValueRef? = nil

		for decl in node.decls {
			lastReturn = visit(decl, context: module)
		}

		return lastReturn ?? .void()
	}

	func visit(_ node: IfStmtSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		let condition = LLVMBuildICmp(
			builder.ref,
			LLVMIntEQ,
			visit(node.condition, context: module).unwrap(),
			LLVM.IntValue.i1(1).ref,
			""
		)

		let thenBlock = LLVMAppendBasicBlockInContext(
			module.context.ref,
			currentFunction.ref,
			"then"
		)

		let elseBlock = LLVMAppendBasicBlockInContext(
			module.context.ref,
			currentFunction.ref,
			"else"
		)

		LLVMBuildCondBr(
			builder.ref,
			condition,
			thenBlock,
			elseBlock
		)

		LLVMPositionBuilderAtEnd(builder.ref, thenBlock)
		_ = visit(node.then, context: module)

		LLVMPositionBuilderAtEnd(builder.ref, elseBlock)

		if let elseExpr = node.else {
			_ = visit(elseExpr, context: module)
		}

		return .void()
	}

	func visit(_: StmtSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_ node: WhileStmtSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		let currentFn = currentFunction

		let loopConditionBlock = LLVMAppendBasicBlockInContext(module.context.ref, currentFunction.ref, "loopcond")
		let loopBodyBlock = LLVMAppendBasicBlockInContext(module.context.ref, currentFunction.ref, "loopbody")
		let loopExitBlock = LLVMAppendBasicBlockInContext(module.context.ref, currentFunction.ref, "loopexit")

		// Jump to the loop condition
		LLVMBuildBr(builder.ref, loopConditionBlock)

		// Evaluate the condition, if it's true, jump to loop body, else jump to exit
		LLVMPositionBuilderAtEnd(builder.ref, loopConditionBlock)
		let condition = LLVMBuildICmp(
			builder.ref,
			LLVMIntEQ,
			visit(node.condition, context: module).unwrap(),
			LLVM.IntValue.i1(1).ref,
			""
		)
		LLVMBuildCondBr(builder.ref, condition, loopBodyBlock, loopExitBlock)

		// Write the body of the loop
		LLVMPositionBuilderAtEnd(builder.ref, loopBodyBlock)
		_ = visit(node.body, context: module)
		// Jump back to the condition when we're done here
		LLVMBuildBr(builder.ref, loopConditionBlock)

		// Finally, move the builder to our post loop block where stuff can continue
		LLVMPositionBuilderAtEnd(builder.ref, loopExitBlock)

		self.currentFunction = currentFn
		return .void()
	}

	func visit(_ node: ReturnStmtSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		let retVal: any LLVM.IRValue = visit(node.value, context: module).unwrap()
		return .value(retVal)
	}

	func visit(_ node: GroupExpr, context module: LLVM.Module) -> LLVM.IRValueRef {
		visit(node.expr, context: module)
	}

	func visit(_ node: CallExprSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		LLVMDumpModule(module.ref)
		if let callee = node.callee.as(VariableExprSyntax.self) {
			let fn = resolveFunction(named: callee.name.lexeme, in: module)!
			var args: [LLVMValueRef?] = node.arguments.arguments.map {
				switch visit($0, context: module) {
				case let .value(value):
					value.ref
				default:
					fatalError("not yet")
				}
			}

			let ref = args.withUnsafeMutableBufferPointer {
				LLVMBuildCall2(
					builder.ref,
					fn.type.ref,
					fn.ref,
					$0.baseAddress,
					UInt32(node.arguments.count),
					""
				)
			}

			return .value(ref!)
		}

		return .void()
	}

	func visit(_ node: UnaryExprSyntax, context: LLVM.Module) -> LLVM.IRValueRef {
		let val: any LLVM.IRValue = visit(node.rhs, context: context).unwrap()

		return switch node.op.kind {
		case .bang, .minus:
			.value(LLVMBuildNeg(builder.ref, val.ref, ""))
		@unknown default:
			.value(LLVMIsAPoisonValue(val.ref))
		}
	}

	func visit(_ node: BinaryExprSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		let lhs: any LLVM.IRValue = visit(node.lhs, context: module).unwrap()
		let rhs: any LLVM.IRValue = visit(node.rhs, context: module).unwrap()

		let ref = switch node.op.kind {
		case .plus: LLVMBuildAdd(builder.ref, lhs.ref, rhs.ref, "")
		case .minus: LLVMBuildSub(builder.ref, lhs.ref, rhs.ref, "")
		case .star: LLVMBuildMul(builder.ref, lhs.ref, rhs.ref, "")
		case .less: LLVMBuildICmp(builder.ref, LLVMIntSLT, lhs.ref, rhs.ref, "less")
		case .lessEqual: LLVMBuildICmp(builder.ref, LLVMIntSLE, lhs.ref, rhs.ref, "sle")
		default:
			fatalError("unhandled binary op: \(node.op)")
		}

		return .value(ref!)
	}

	func visit(_ node: IdentifierSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		if case let .defined(val) = currentFunction.locals[node.lexeme] {
			return .value(val)
		} else if currentFunction.locals[node.lexeme] == .declared {
			fatalError("variable declared but not defined: \(node.lexeme)")
		}

		fatalError("unknown variable: \(node.lexeme)")
	}

	func visit(_ node: IntLiteralSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		guard let val = Int(node.lexeme) else {
			fatalError("could not parse int")
		}

		let intValue = LLVM.IntValue.i32(val)

		return .value(intValue)
	}

	func visit(_: StringLiteralSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_ node: VariableExprSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		let name = node.name

		if case let .defined(val) = currentFunction.locals[name.lexeme] {
			// See if we just have the value already defined
			return .value(val)
		} else if case let .allocated(value) = currentFunction.locals[name.lexeme] {
			// See if it's a stack var
			return .value(LLVMBuildLoad2(builder.ref, value.type.ref, value.ref, name.lexeme))
		} else if let heapValue = heapValues[name.lexeme] {
			// See if it's a heap var
			let load = LLVMBuildLoad2(builder.ref, heapValue.type.ref, heapValue.ref, name.lexeme)!
			return .value(load)
		} else if currentFunction.parameters[name.lexeme] == .declared {
			let paramIndex = currentFunction.type.parameters.firstIndex(where: { $0.0 == name.lexeme })!
			return .value(LLVMGetParam(currentFunction.ref, UInt32(paramIndex)))
		}

		fatalError("unknown variable: \(name.lexeme)")
	}

	func visit(_ node: AssignmentExpr, context module: LLVM.Module) -> LLVM.IRValueRef {
		switch node.lhs {
		case let lhs as VariableExprSyntax:
			let value: any LLVM.IRValue = visit(node.rhs, context: module).unwrap()

			if case let .allocated(val) = currentFunction.locals[lhs.name.lexeme] {
				val.store(value, in: builder)
				return .void()
			}

			if let heapValue = heapValues[lhs.name.lexeme] {
				heapValue.store(value, in: builder)
				return .void()
			}

			fatalError("undefined variable: \(lhs.name.lexeme)")
		default:
			fatalError("not yet")
		}

		return .void()
	}

	func visit(_ node: LiteralExprSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		switch node.kind {
		case .true:
			.value(.i1(1).ref)
		case .false:
			.value(.i1(0).ref)
		case .nil:
			.value(.i1(0).ref)
		}
	}

	func visit(_: PropertyAccessExpr, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: ArrayLiteralSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_ node: IfExprSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		let condition = LLVMBuildICmp(
			builder.ref,
			LLVMIntEQ,
			visit(node.condition, context: module).unwrap(),
			LLVM.IntValue.i1(1).ref,
			""
		)

		let insertFunction = LLVMGetBasicBlockParent(LLVMGetInsertBlock(builder.ref))!

		let thenBlock = LLVMAppendBasicBlockInContext(module.context.ref, insertFunction, "then")
		let elseBlock = LLVMAppendBasicBlockInContext(module.context.ref, insertFunction, "else")
		let mergeBlock = LLVMAppendBasicBlockInContext(module.context.ref, insertFunction, "ifcont")

		LLVMBuildCondBr(builder.ref, condition, thenBlock, elseBlock)

		LLVMPositionBuilderAtEnd(builder.ref, thenBlock)
		let thenValue: any LLVM.IRValue = visit(node.thenBlock, context: module).unwrap()
		LLVMBuildBr(builder.ref, mergeBlock)

		LLVMPositionBuilderAtEnd(builder.ref, elseBlock)
		let elseValue: any LLVM.IRValue = visit(node.elseBlock, context: module).unwrap()
		LLVMBuildBr(builder.ref, mergeBlock)

		LLVMPositionBuilderAtEnd(builder.ref, mergeBlock)
		let phiRetType = map(bindings.type(for: node)!.type)
		let phiNode = LLVMBuildPhi(builder.ref, phiRetType.ref, "merge")!

		var values: [LLVMValueRef?] = [thenValue.ref, elseValue.ref]
		var blocks: [LLVMBasicBlockRef?] = [thenBlock, elseBlock]
		let count = values.count

		values.withUnsafeMutableBufferPointer { valuesPtr in
			blocks.withUnsafeMutableBufferPointer { blocksPtr in
				LLVMAddIncoming(
					phiNode,
					valuesPtr.baseAddress,
					blocksPtr.baseAddress,
					UInt32(count)
				)
			}
		}

		return .value(phiNode)
	}

	func visit(_ node: UnaryOperator, context _: LLVM.Module) -> LLVM.IRValueRef {
		switch node.kind {
		case .minus:
			.op(LLVMFNeg)
		case .bang:
			.op(LLVMFNeg)
		}
	}

	func visit(_ node: BinaryOperatorSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		switch node.kind {
		case .plus:
			.op(LLVMAdd)
		case .minus:
			.op(LLVMSub)
		case .star:
			.op(LLVMMul)
		default:
			fatalError()
		}
	}

	func visit(_: ArgumentListSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: ParameterListSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: ErrorSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: TypeDeclSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}
}
