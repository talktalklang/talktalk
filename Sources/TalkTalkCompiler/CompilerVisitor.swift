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

	func visit(_ node: FunctionDeclSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		let ret = bindings.type(for: node.name)?.type.returns?.value
		let returnType: any LLVM.IRType = switch ret {
		case .int: .i32()
		default:
			fatalError()
		}

		let parameters: [(String, any LLVM.IRType)] = node.parameters.parameters.reduce(into: []) { res, parameter in
			return switch bindings.type(for: parameter)?.type {
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

		module.functionTypes[functionType.ref] = functionType

		// TODO: validate we're not redeclaring the same function
		let function = builder.addFunction(named: node.name.lexeme, functionType)!

		let oldFunction = self.currentFunction
		self.currentFunction = function
		let entry = LLVMAppendBasicBlockInContext(module.context.ref, function.ref, "entry")
		LLVMPositionBuilderAtEnd(builder.ref, entry)

		for parameter in node.parameters.parameters {
			function.locals[parameter.lexeme] = .declared
		}

		_ = visit(node.body, context: module)

		self.currentFunction = oldFunction
		let block = LLVMGetLastBasicBlock(oldFunction.ref)
		LLVMPositionBuilderAtEnd(builder.ref, block)

		return .value(function.ref)
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

	func visit(_ node: BlockStmtSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		for decl in node.decls {
			_ = visit(decl, context: module)
		}

		return .void()
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

	func visit(_ node: ReturnStmtSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		let ret = visit(node.value, context: module)

		LLVMBuildRet(builder.ref, ret.unwrap())

		return ret
	}

	func visit(_: GroupExpr, context _: LLVM.Module) -> LLVM.IRValueRef {
		.void()
	}

	func visit(_ node: CallExprSyntax, context module: LLVM.Module) -> LLVM.IRValueRef {
		if let callee = node.callee.as(VariableExprSyntax.self) {
			let fn = module.function(named: callee.name.lexeme)!
			var args: [LLVMValueRef?] = node.arguments.arguments.map {
				switch visit($0, context: module) {
				case let .value(value):
					value.ref
				default:
					fatalError("not yet")
				}
			}

			let ref = args.withUnsafeMutableBufferPointer {
				return LLVMBuildCall2(
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

	func visit(_ node: VariableExprSyntax, context: LLVM.Module) -> LLVM.IRValueRef {
		let name = node.name

		if case let .defined(val) = currentFunction.locals[name.lexeme] {
			return .value(val)
		} else if currentFunction.locals[name.lexeme] == .declared {
			let paramIndex = currentFunction.type.parameters.firstIndex(where: { $0.0 == name.lexeme })!
			return .value(LLVMGetParam(currentFunction.ref, UInt32(paramIndex)))
		}

		fatalError("unknown variable: \(name.lexeme)")
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
