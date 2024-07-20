//
//  SemanticASTVisitor.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct SemanticASTVisitor: ASTVisitor {
	let rootBinding = Binding()
	let ast: any Syntax

	public init(ast: some Syntax) {
		self.ast = ast
	}

	public func visit() -> any SemanticNode {
		ast.accept(self, context: rootBinding)
	}

	// MARK: Visits

	public func visit(_ node: TypeDeclSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: ErrorSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: ParameterListSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: ArgumentListSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: BinaryOperatorSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: UnaryOperator, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: IfExprSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: ArrayLiteralSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: PropertyAccessExpr, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: LiteralExprSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: AssignmentExpr, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: VariableExprSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: StringLiteralSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: IntLiteralSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: IdentifierSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: BinaryExprSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: UnaryExprSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: CallExprSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: GroupExpr, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: ReturnStmtSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: WhileStmtSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: StmtSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: IfStmtSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: BlockStmtSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: ExprStmtSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: PropertyDeclSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: InitDeclSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: ClassDeclSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: LetDeclSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: VarDeclSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: FunctionDeclSyntax, context: Binding) -> Function {
		.placeholder(context)
	}
	
	public func visit(_ node: ProgramSyntax, context: Binding) -> Program {
		let binding = Binding(
			parent: nil,
			children: [],
			locals: [:],
			environment: Environment()
		)

		return Program(syntax: node, binding: binding, declarations: [])
	}
}
