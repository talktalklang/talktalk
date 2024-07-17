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
	var builder: LLVM.Builder
	var module: LLVM.Module
	var currentFunction: LLVM.Function

	init(builder: LLVM.Builder, module: LLVM.Module) {
		self.builder = builder
		self.module = module

		let mainType = LLVM.FunctionType(
			context: .global,
			returning: .i32(.global),
			parameters: [],
			isVarArg: false
		)

		let function = builder.addFunction(named: "main", mainType)!
		let blockRef = LLVMAppendBasicBlockInContext(module.context.ref, function.ref, "entry")
		currentFunction = function

		LLVMPositionBuilderAtEnd(builder.ref, blockRef)
	}

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

	func visit(_: FunctionDeclSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: VarDeclSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
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

	func visit(_: BlockStmtSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: IfStmtSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: StmtSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: WhileStmtSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: ReturnStmtSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: GroupExpr, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: CallExprSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
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
		default:
			fatalError("unhandled binary op: \(node.op)")
		}

		LLVMDumpValue(ref)

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

	func visit(_ node: VariableExprSyntax, context: LLVM.Module) -> LLVM.IRValueRef {
		visit(node.name, context: context)
	}

	func visit(_: AssignmentExpr, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: LiteralExprSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: PropertyAccessExpr, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: ArrayLiteralSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_: IfExprSyntax, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
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
