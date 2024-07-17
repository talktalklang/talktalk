//
//  CompilerVisitor.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
import TalkTalkSyntax
import TalkTalkTyper
import C_LLVM

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

	func visit(_ node: FunctionDeclSyntax, context module: LLVM.Module) -> LLVM.Function? {
		nil
	}

	func visit(_ node: VarDeclSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: ClassDeclSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: InitDeclSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: PropertyDeclSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: ExprStmtSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		visit(node.expr, context: module)
	}

	func visit(_ node: BlockStmtSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: IfStmtSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: StmtSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: WhileStmtSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: ReturnStmtSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: GroupExpr, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: CallExprSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: UnaryExprSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: BinaryExprSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		let lhs = visit(node.lhs, context: module)!
		let rhs = visit(node.rhs, context: module)!

		let result = LLVMBuildAdd(builder.ref, lhs.ref, rhs.ref, "addtmp")

		LLVMBuildRet(builder.ref, result)

		return nil
	}

	func visit(_ node: IdentifierSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: IntLiteralSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		LLVM.IntType(width: 32, context: module.context).constant(Int(node.lexeme)!)
	}

	func visit(_ node: StringLiteralSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: VariableExprSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: AssignmentExpr, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: LiteralExprSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: PropertyAccessExpr, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: ArrayLiteralSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: IfExprSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: UnaryOperator, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: BinaryOperatorSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: ArgumentListSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: ParameterListSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: ErrorSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}

	func visit(_ node: TypeDeclSyntax, context module: LLVM.Module) -> LLVM.IRValue? {
		nil
	}
}
