public struct ASTFormatter: ASTVisitor {
	public struct Context {
		public init() { }
	}

	let root: any Syntax
	var indent = 0

	public static func format(_ root: any Syntax) -> String {
		let formatter = ASTFormatter(root: root)
		let context = Context()
		return root.accept(formatter, context: context)
	}

	public static func print(_ root: any Syntax) {
		let formatter = ASTFormatter(root: root)
		let context = Context()
		Swift.print(root.accept(formatter, context: context))
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

	// MARK: Visits

	public func visit(_ node: LetDeclSyntax, context: Context) -> String {
		var result = "let \(visit(node.variable, context: context))"

		if let typeDecl = node.typeDecl {
			result += " \(visit(typeDecl, context: context))"
		}

		if let expr = node.expr {
			result += " = \(visit(expr, context: context))"
		}

		return result
	}

	public func visit(_ node: IfExprSyntax, context: Context) -> String {
		var result = "if \(visit(node.condition, context: context)) "
		result += visit(node.thenBlock, context: context)
		result += " else "
		result += visit(node.elseBlock, context: context)
		return result
	}

	public func visit(_ node: PropertyDeclSyntax, context: Context) -> String {
		"var \(visit(node.name, context: context))\(visit(node.typeDecl, context: context))"
	}

	public func visit(_ node: PropertyAccessExpr, context: Context) -> String {
		"\(visit(node.receiver, context: context)).\(visit(node.property, context: context))"
	}

	public func visit(_ node: LiteralExprSyntax, context _: Context) -> String {
		node.description
	}

	public func visit(_ node: UnaryOperator, context _: Context) -> String {
		node.description
	}

	public func visit(_ node: any Syntax, context: Context) -> String {
		node.accept(self, context: context)
	}

	public func visit(_ node: TypeDeclSyntax, context _: Context) -> String {
		": \(node.name.lexeme)"
	}

	public func visit(_ node: InitDeclSyntax, context: Context) -> String {
		var result = "init(\(visit(node.parameters, context: context))) "
		result += visit(node.body, context: context)
		result += "\n"
		return result
	}

	public func visit(_ node: ProgramSyntax, context: Context) -> String {
		node.decls.map {
			visit($0, context: context)
		}.joined(separator: "\n")
	}

	public func visit(_ node: AssignmentExpr, context: Context) -> String {
		"\(visit(node.lhs, context: context)) = \(visit(node.rhs, context: context))"
	}

	public func visit(_ node: IfStmtSyntax, context: Context) -> String {
		var result = "if \(visit(node.condition, context: context)) "
		result += visit(node.then, context: context)

		return result
	}

	public func visit(_ node: ReturnStmtSyntax, context: Context) -> String {
		"return \(visit(node.value, context: context))"
	}

	public func visit(_ node: WhileStmtSyntax, context: Context) -> String {
		var result = "\nwhile \(visit(node.condition, context: context)) "
		result += visit(node.body, context: context)
		return result
	}

	public func visit(_ node: GroupExpr, context: Context) -> String {
		"(\(visit(node.expr, context: context))"
	}

	public func visit(_ node: VarDeclSyntax, context: Context) -> String {
		if let expr = node.expr {
			"var \(visit(node.variable, context: context)) = \(visit(expr, context: context))"
		} else {
			"var \(visit(node.variable, context: context))"
		}
	}

	public func visit(_ node: CallExprSyntax, context: Context) -> String {
		var result = visit(node.callee, context: context)
		result += "("
		result += visit(node.arguments, context: context)
		result += ")"
		return result
	}

	public func visit(_ node: ExprStmtSyntax, context: Context) -> String {
		visit(node.expr, context: context)
	}

	public func visit(_ node: BlockStmtSyntax, context: Context) -> String {
		var result = "{\n"
		result += node.decls.map { decl in
			indenting {
				$0.visit(decl, context: context)
			}
		}.joined(separator: "\n")
		result += "\n}"
		return result
	}

	public func visit(_ node: UnaryExprSyntax, context: Context) -> String {
		visit(node.op, context: context) + visit(node.rhs, context: context)
	}

	public func visit(_ node: BinaryExprSyntax, context: Context) -> String {
		visit(node.lhs, context: context) + visit(node.op, context: context) + visit(node.rhs, context: context)
	}

	public func visit(_ node: IdentifierSyntax, context _: Context) -> String {
		node.lexeme
	}

	public func visit(_ node: IntLiteralSyntax, context _: Context) -> String {
		node.lexeme
	}

	public func visit(_ node: ArgumentListSyntax, context: Context) -> String {
		node.arguments.map {
			visit($0, context: context)
		}.joined(separator: ", ")
	}

	public func visit(_ node: ArrayLiteralSyntax, context: Context) -> String {
		var result = "["
		result += visit(node.elements, context: context)
		result += "]"
		return result
	}

	public func visit(_ node: ClassDeclSyntax, context: Context) -> String {
		var result = "class \(visit(node.name, context: context))"
		result += visit(node.body, context: context)
		result += "\n"
		return result
	}

	public func visit(_ node: FunctionDeclSyntax, context: Context) -> String {
		var result = "func " + visit(node.name, context: context)
		result += "(\(visit(node.parameters, context: context))) "
		result += visit(node.body, context: context)
		result += "\n"
		return result
	}

	public func visit(_ node: VariableExprSyntax, context: Context) -> String {
		visit(node.name, context: context)
	}

	public func visit(_ node: ParameterListSyntax, context: Context) -> String {
		node.parameters.map {
			visit($0, context: context)
		}.joined(separator: ", ")
	}

	public func visit(_ node: StringLiteralSyntax, context _: Context) -> String {
		node.lexeme
	}

	public func visit(_ node: BinaryOperatorSyntax, context _: Context) -> String {
		" " + node.description + " "
	}

	public func visit(_: StmtSyntax, context _: Context) -> String {
		""
	}

	public func visit(_ node: ErrorSyntax, context _: Context) -> String {
		node.description
	}
}
