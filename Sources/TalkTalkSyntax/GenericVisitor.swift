//
//  GenericVisitor.swift
//
//
//  Created by Pat Nakajima on 7/14/24.
//
public struct GenericVisitor<Context>: ASTVisitor {
	let perform: (any Syntax, Context) -> Context

	public init(perform: @escaping (any Syntax, Context) -> Context) {
		self.perform = perform
	}

	// MARK: Visits

	mutating func visit(_ expr: any Syntax, context: Context) -> Context {
		var context = perform(expr, context)
		context = expr.accept(&self, context: context)
		return context
	}

	public mutating func visit(_ node: ProgramSyntax, context: Context) -> Context {
		var context = perform(node, context)
		for decl in node.decls {
			context = decl.accept(&self, context: context)
		}
		return context
	}

	public mutating func visit(_ node: FunctionDeclSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.name, context: context)
		context = visit(node.parameters, context: context)
		if let typeDecl = node.typeDecl {
			context = visit(typeDecl, context: context)
		}
		context = visit(node.body, context: context)
		return context
	}

	public mutating func visit(_ node: VarDeclSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.variable, context: context)

		if let expr = node.expr {
			_ = expr.accept(&self, context: context)
		}

		return context
	}

	public mutating func visit(_ node: ClassDeclSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.name, context: context)
		context = visit(node.body, context: context)
		return context
	}

	public mutating func visit(_ node: InitDeclSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.parameters, context: context)
		context = visit(node.body, context: context)
		return context
	}

	public mutating func visit(_ node: PropertyDeclSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.name, context: context)
		context = visit(node.typeDecl, context: context)

		if let value = node.value {
			context = visit(value, context: context)
		}

		return context
	}

	public mutating func visit(_ node: ExprStmtSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.expr, context: context)
		return context
	}

	public mutating func visit(_ node: BlockStmtSyntax, context: Context) -> Context {
		var context = perform(node, context)
		for decl in node.decls {
			context = visit(decl, context: context)
		}

		return context
	}

	public mutating func visit(_ node: IfStmtSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.condition, context: context)
		context = visit(node.body, context: context)
		return context
	}

	public mutating func visit(_ node: StmtSyntax, context: Context) -> Context {
		perform(node, context)
	}

	public mutating func visit(_ node: WhileStmtSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.condition, context: context)
		context = visit(node.body, context: context)
		return context
	}

	public mutating func visit(_ node: ReturnStmtSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.value, context: context)
		return context
	}

	public mutating func visit(_ node: GroupExpr, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.expr, context: context)
		return context
	}

	public mutating func visit(_ node: CallExprSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.callee, context: context)
		context = visit(node.arguments, context: context)
		return context
	}

	public mutating func visit(_ node: UnaryExprSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.op, context: context)
		context = visit(node.rhs, context: context)
		return context
	}

	public mutating func visit(_ node: BinaryExprSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.lhs, context: context)
		context = visit(node.op, context: context)
		context = visit(node.rhs, context: context)
		return context
	}

	public mutating func visit(_ node: IdentifierSyntax, context: Context) -> Context {
		perform(node, context)
	}

	public mutating func visit(_ node: IntLiteralSyntax, context: Context) -> Context {
		perform(node, context)
	}

	public mutating func visit(_ node: StringLiteralSyntax, context: Context) -> Context {
		perform(node, context)
	}

	public mutating func visit(_ node: VariableExprSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.name, context: context)
		return context
	}

	public mutating func visit(_ node: AssignmentExpr, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.lhs, context: context)
		context = visit(node.rhs, context: context)
		return context
	}

	public mutating func visit(_ node: LiteralExprSyntax, context: Context) -> Context {
		perform(node, context)
	}

	public mutating func visit(_ node: PropertyAccessExpr, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.receiver, context: context)
		context = visit(node.property, context: context)
		return context
	}

	public mutating func visit(_ node: ArrayLiteralSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.elements, context: context)
		return context
	}

	public mutating func visit(_ node: IfExprSyntax, context: Context) -> Context {
		var context = perform(node, context)
		context = visit(node.condition, context: context)
		context = visit(node.thenBlock, context: context)
		context = visit(node.elseBlock, context: context)
		return context
	}

	public mutating func visit(_ node: UnaryOperator, context: Context) -> Context {
		perform(node, context)
	}

	public mutating func visit(_ node: BinaryOperatorSyntax, context: Context) -> Context {
		perform(node, context)
	}

	public mutating func visit(_ node: ArgumentListSyntax, context: Context) -> Context {
		var context = perform(node, context)
		for argument in node.arguments {
			context = visit(argument, context: context)
		}
		return context
	}

	public mutating func visit(_ node: ParameterListSyntax, context: Context) -> Context {
		var context = perform(node, context)
		for parameter in node.parameters {
			context = visit(parameter, context: context)
		}
		return context
	}

	public mutating func visit(_ node: ErrorSyntax, context: Context) -> Context {
		perform(node, context)
	}

	public mutating func visit(_ node: TypeDeclSyntax, context: Context) -> Context {
		var context = perform(node, context)
		return visit(node.name, context: context)
	}
}
