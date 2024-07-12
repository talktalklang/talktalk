

public struct ASTFormatter: ASTVisitor {
	public struct Context {}

	let root: any Syntax
	var indent = 0

	public static func format(_ root: any Syntax) -> String {
		var formatter = ASTFormatter(root: root)
		var context = Context()
		return root.accept(&formatter, context: &context)
	}

	public static func print(_ root: any Syntax) {
		var formatter = ASTFormatter(root: root)
		var context = Context()
		Swift.print(root.accept(&formatter, context: &context))
	}

	public init(root: any Syntax) {
		self.root = root
	}

	public func indenting(perform: (inout ASTFormatter) -> String) -> String {
		var copy = self
		copy.indent += 1
		let indentation = String(repeating: "\t", count: copy.indent)
		return perform(&copy).components(separatedBy: .newlines).map {
			indentation + $0
		}.joined(separator: "\n")
	}

	public mutating func visit(_ node: PropertyAccessExpr, context: inout Context) -> String {
		"\(visit(node.receiver, context: &context)).\(visit(node.property, context: &context))"
	}

	public func visit(_ node: LiteralExprSyntax, context: inout Context) -> String {
		node.description
	}

	public mutating func visit(_ node: UnaryOperator, context: inout Context) -> String {
		node.description
	}

	public mutating func visit(_ node: any Syntax, context: inout Context) -> String {
		node.accept(&self, context: &context)
	}

	public mutating func visit(_ node: TypeDeclSyntax, context: inout Context) -> String {
		": \(node.name.lexeme)"
	}

	public mutating func visit(_ node: InitDeclSyntax, context: inout Context) -> String {
		var result = "init(\(visit(node.parameters, context: &context))) "
		result += visit(node.body, context: &context)
		result += "\n"
		return result
	}

	public mutating func visit(_ node: ProgramSyntax, context: inout Context) -> String {
		node.decls.map {
			visit($0, context: &context)
		}.joined(separator: "\n")
	}

	public mutating func visit(_ node: AssignmentExpr, context: inout Context) -> String {
		"\(visit(node.lhs, context: &context)) = \(visit(node.rhs, context: &context))"
	}

	public mutating func visit(_ node: IfStmtSyntax, context: inout Context) -> String {
		var result = "if \(visit(node.condition, context: &context))) "
		result += visit(node.body, context: &context)

		return result
	}

	public mutating func visit(_ node: ReturnStmtSyntax, context: inout Context) -> String {
		"return \(visit(node.value, context: &context))"
	}

	public mutating func visit(_ node: WhileStmtSyntax, context: inout Context) -> String {
		var result = "\nwhile \(visit(node.condition, context: &context)) "
		result += visit(node.body, context: &context)
		return result
	}

	public mutating func visit(_ node: GroupExpr, context: inout Context) -> String {
		"(\(visit(node.expr, context: &context))"
	}

	public mutating func visit(_ node: VarDeclSyntax, context: inout Context) -> String {
		if let expr = node.expr {
			"var \(visit(node.variable, context: &context)) = \(visit(expr, context: &context))"
		} else {
			"var \(visit(node.variable, context: &context))"
		}
	}

	public mutating func visit(_ node: CallExprSyntax, context: inout Context) -> String {
		var result = visit(node.callee, context: &context)
		result += "("
		result += visit(node.arguments, context: &context)
		result += ")"
		return result
	}

	public mutating func visit(_ node: ExprStmtSyntax, context: inout Context) -> String {
		visit(node.expr, context: &context)
	}

	public mutating func visit(_ node: BlockStmtSyntax, context: inout Context) -> String {
		var result = "{\n"
		result += node.decls.map { decl in
			indenting {
				$0.visit(decl, context: &context)
			}
		}.joined(separator: "\n")
		result += "\n}"
		return result
	}

	public mutating func visit(_ node: UnaryExprSyntax, context: inout Context) -> String {
		visit(node.op, context: &context) + visit(node.rhs, context: &context)
	}

	public mutating func visit(_ node: BinaryExprSyntax, context: inout Context) -> String {
		visit(node.lhs, context: &context) + visit(node.op, context: &context) + visit(node.rhs, context: &context)
	}

	public mutating func visit(_ node: IdentifierSyntax, context: inout Context) -> String {
		node.lexeme
	}

	public mutating func visit(_ node: IntLiteralSyntax, context: inout Context) -> String {
		node.lexeme
	}

	public mutating func visit(_ node: ArgumentListSyntax, context: inout Context) -> String {
		node.arguments.map {
			visit($0, context: &context)
		}.joined(separator: ", ")
	}

	public mutating func visit(_ node: ArrayLiteralSyntax, context: inout Context) -> String {
		var result = "["
		result += visit(node.elements, context: &context)
		result += "]"
		return result
	}

	public mutating func visit(_ node: ClassDeclSyntax, context: inout Context) -> String {
		var result = "class \(visit(node.name, context: &context))"
		result += visit(node.body, context: &context)
		result += "\n"
		return result
	}

	public mutating func visit(_ node: FunctionDeclSyntax, context: inout Context) -> String {
		var result = "func " + visit(node.name, context: &context)
		result += "(\(visit(node.parameters, context: &context))) "
		result += visit(node.body, context: &context)
		result += "\n"
		return result
	}

	public mutating func visit(_ node: VariableExprSyntax, context: inout Context) -> String {
		visit(node.name, context: &context)
	}

	public mutating func visit(_ node: ParameterListSyntax, context: inout Context) -> String {
		node.parameters.map {
			visit($0, context: &context)
		}.joined(separator: ", ")
	}

	public mutating func visit(_ node: StringLiteralSyntax, context: inout Context) -> String {
		node.lexeme
	}

	public mutating func visit(_ node: BinaryOperatorSyntax, context: inout Context) -> String {
		" " + node.description + " "
	}

	public mutating func visit(_: StmtSyntax, context: inout Context) -> String {
		""
	}

	public mutating func visit(_ node: ErrorSyntax, context: inout Context) -> String {
		node.description
	}
}
