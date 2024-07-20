//
//  SemanticASTVisitor.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct SemanticError {
	public var location: any Syntax
	public var message: String
}

// The semantic ast visitor is responsible for converting the AST to a new
// tree that contains info about types and closures and scopes and whatnot
public struct SemanticASTVisitor: ASTVisitor {
	public let rootBinding = Binding()
	let ast: any Syntax

	public init(ast: some Syntax) {
		self.ast = ast
	}

	public func visit() -> any SemanticNode {
		ast.accept(self, context: rootBinding)
	}

	func error(_ syntax: any Syntax, _ message: String) {
		#if DEBUG
		print("Error at \(syntax.description): \(message)")
		#endif

		rootBinding.errors.append(.init(location: syntax, message: message))
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
		switch node.kind {
		case .true:
			Literal(syntax: node, binding: context, type: .bool)
		case .false:
			Literal(syntax: node, binding: context, type: .bool)
		case .nil:
			// TODO: hmm
			Literal(syntax: node, binding: context, type: .bool)
		}

	}
	
	public func visit(_ node: AssignmentExpr, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: VariableExprSyntax, context: Binding) -> any SemanticNode {
		.placeholder(context)
	}
	
	public func visit(_ node: StringLiteralSyntax, context: Binding) -> any SemanticNode {
		Literal(syntax: node, binding: context, type: .string)
	}
	
	public func visit(_ node: IntLiteralSyntax, context: Binding) -> any SemanticNode {
		Literal(syntax: node, binding: context, type: .int)
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
	
	public func visit(_ node: LetDeclSyntax, context binding: Binding) -> any SemanticNode {
		handleVarLet(node, binding: binding)
	}
	
	public func visit(_ node: VarDeclSyntax, context binding: Binding) -> any SemanticNode {
		handleVarLet(node, binding: binding)
	}
	
	public func visit(_ node: FunctionDeclSyntax, context: Binding) -> any SemanticNode {
		// Introduce a new scope
		let binding = context.child()
		
		return .placeholder(context)
	}
	
	public func visit(_ node: ProgramSyntax, context binding: Binding) -> any SemanticNode {
		var declarations = node.decls.map {
			visit($0, context: binding) as! Declaration
		}

		return Program(syntax: node, binding: binding, declarations: declarations)
	}

	// MARK: Helpers

	func handleVarLet(_ node: any VarLetDecl, binding: Binding) -> any SemanticNode {
		let name = node.variable.lexeme

		let typeDeclNode: (any SemanticNode)? = if let typeDecl = node.typeDecl {
			visit(typeDecl, context: binding)
		} else {
			nil
		}

		if let expr = node.expr {
			let exprNode = visit(expr, context: binding)

			// Check to see if there's a type decl. If it doesn't agree with
			// the expr node, we're in trouble
			if let typeDeclNode, typeDeclNode.type.assignable(from: exprNode.type) {
				error(node, "Cannot assign \(exprNode.type) to \(typeDeclNode.type)")
			}

			binding.bind(name: name, to: exprNode)
		} else {
			binding.bind(name: name, to: .unknown(syntax: node, binding: binding))
		}

		return Declaration(syntax: node, binding: binding)
	}
}
