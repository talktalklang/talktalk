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
	var ast: ProgramSyntax
	var builder: LLVM.Builder
	var module: LLVM.Module

	init(ast: ProgramSyntax, builder: LLVM.Builder, module: LLVM.Module) {
		self.ast = ast
		self.builder = builder
		self.module = module
	}

	func visit(_ node: ProgramSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		for decl in node.decls {
			_ = visit(decl, context: module)
		}

		return nil
	}

	func visit(_: FunctionDeclSyntax, context _: LLVM.Module) -> LLVM.Function? {
		nil
	}

	func visit(_: VarDeclSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: ClassDeclSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: InitDeclSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: PropertyDeclSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: ExprStmtSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		visit(node.expr, context: module)
	}

	func visit(_: BlockStmtSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: IfStmtSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: StmtSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: WhileStmtSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: ReturnStmtSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: GroupExpr, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: CallExprSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: UnaryExprSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: BinaryExprSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		let lhs = visit(node.lhs, context: module)!
		let rhs = visit(node.rhs, context: module)!

		let result = LLVMBuildAdd(builder.ref, lhs.ref, rhs.ref, "addtmp")

		LLVMBuildRet(builder.ref, result)

		return nil
	}

	func visit(_: IdentifierSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: IntLiteralSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		LLVM.IntType(width: 32, context: module.context).constant(Int(node.lexeme)!)
	}

	func visit(_: StringLiteralSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: VariableExprSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: AssignmentExpr, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: LiteralExprSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: PropertyAccessExpr, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: ArrayLiteralSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: IfExprSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: UnaryOperator, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: BinaryOperatorSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: ArgumentListSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: ParameterListSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: ErrorSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_: TypeDeclSyntax, context _: LLVM.Module) -> LLVM.IRValue? {
		nil
	}
}
