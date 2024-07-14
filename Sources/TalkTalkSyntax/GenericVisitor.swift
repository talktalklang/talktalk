//
//  GenericVisitor.swift
//  
//
//  Created by Pat Nakajima on 7/14/24.
//
public struct GenericVisitor<Value>: ASTVisitor {
	public struct Context {
		var depth: Int = 0

		func nest() -> Context {
			var copy = self
			copy.depth += 1
			return copy
		}
	}

	let perform: (any Syntax, Context) -> Value

	// MARK: Visits

	mutating func visit(_ expr: any Syntax, context: Context) -> Value {
		_ = perform(expr, context)
		_ = expr.accept(&self, context: context)
	}

	public mutating func visit(_ node: ProgramSyntax, context: Context) -> Value {
		let result = perform(node, context)
		for decl in node.decls {
			_ = decl.accept(&self, context: context.nest())
		}
		return result
	}

	public mutating func visit(_ node: FunctionDeclSyntax, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.name, context: context.nest())
		_ = visit(node.parameters, context: context.nest())
		if let typeDecl = node.typeDecl {
			_ = visit(typeDecl, context: context.nest())
		}
		_ = visit(node.body, context: context.nest())
	}

	public mutating func visit(_ node: VarDeclSyntax, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.variable, context: context.nest())

		if let expr = node.expr {
			_ = expr.accept(&self, context: context.nest())
		}
	}

	public mutating func visit(_ node: ClassDeclSyntax, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.name, context: context)
		_ = visit(node.body, context: context)
	}

	public mutating func visit(_ node: InitDeclSyntax, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.parameters, context: context)
		_ = visit(node.body, context: context)
	}

	public mutating func visit(_ node: PropertyDeclSyntax, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.name, context: context)
		_ = visit(node.typeDecl, context: context)

		if let value = node.value {
			_ = visit(value, context: context)
		}
	}

	public mutating func visit(_ node: ExprStmtSyntax, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.expr, context: context)
	}

	public mutating func visit(_ node: BlockStmtSyntax, context: Context) -> Value {
		_ = perform(node, context)
		for decl in node.decls {
			_ = visit(decl, context: context.nest())
		}
	}

	public mutating func visit(_ node: IfStmtSyntax, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.condition, context: context)
		_ = visit(node.body, context: context)
	}

	public mutating func visit(_ node: StmtSyntax, context: Context) -> Value {
		_ = perform(node, context)
	}

	public mutating func visit(_ node: WhileStmtSyntax, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.condition, context: context)
		_ = visit(node.body, context: context)
	}

	public mutating func visit(_ node: ReturnStmtSyntax, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.value, context: context)
	}

	public mutating func visit(_ node: GroupExpr, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.expr, context: context)
	}

	public mutating func visit(_ node: CallExprSyntax, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.callee, context: context)
		_ = visit(node.arguments, context: context)
	}

	public mutating func visit(_ node: UnaryExprSyntax, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.op, context: context)
		_ = visit(node.rhs, context: context)
	}

	public mutating func visit(_ node: BinaryExprSyntax, context: Context) -> Value {
		_ = perform(node, context)
		_ = visit(node.lhs, context: context)
		_ = visit(node.op, context: context)
		_ = visit(node.rhs, context: context)
	}

	public mutating func visit(_ node: IdentifierSyntax, context: Context) -> Value {
		_ = perform(node, context)
	}

	public mutating func visit(_ node: IntLiteralSyntax, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: StringLiteralSyntax, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: VariableExprSyntax, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: AssignmentExpr, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: LiteralExprSyntax, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: PropertyAccessExpr, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: ArrayLiteralSyntax, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: IfExprSyntax, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: UnaryOperator, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: BinaryOperatorSyntax, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: ArgumentListSyntax, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: ParameterListSyntax, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: ErrorSyntax, context: Context) -> Value {
		<#code#>
	}

	public mutating func visit(_ node: TypeDeclSyntax, context: Context) -> Value {
		<#code#>
	}
}
