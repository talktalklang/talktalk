

public struct ASTFormatter<Root: Syntax>: ASTVisitor {
	let root: Root
	var indent = 0

	public static func print(_ root: Root) {
		var printer = ASTFormatter(root: root)
		Swift.print(root.accept(&printer))
	}

	public init(root: Root) {
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

	public func visit(_ node: LiteralExprSyntax) -> String {
		node.description
	}

	public mutating func visit(_ node: UnaryOperator) -> String {
		node.description
	}

	public mutating func visit(_ node: any Syntax) -> String {
		node.accept(&self)
	}

	public mutating func visit(_ node: ProgramSyntax) -> String {
		node.decls.map {
			visit($0)
		}.joined(separator: "\n")
	}

	public mutating func visit(_ node: AssignmentExpr) -> String {
		"\(visit(node.lhs)) = \(visit(node.rhs))"
	}

	public mutating func visit(_ node: IfStmtSyntax) -> String {
		var result = "if \(visit(node.condition))) {\n"

		result += visit(node.body)

		result += "\n}\n"

		return result
	}

	public mutating func visit(_ node: ReturnStmtSyntax) -> String {
		"return \(visit(node.value))"
	}

	public mutating func visit(_ node: WhileStmtSyntax) -> String {
		var result = "while \(visit(node.condition)) {\n"
		result += visit(node.body)
		result += "\n}\n"
		return result
	}

	public mutating func visit(_ node: GroupExpr) -> String {
		"(\(visit(node.expr))"
	}

	public mutating func visit(_ node: VarDeclSyntax) -> String {
		if let expr = node.expr {
			"var \(visit(node.variable)) = \(visit(expr))"
		} else {
			"var \(visit(node.variable))"
		}
	}

	public mutating func visit(_ node: CallExprSyntax) -> String {
		var result = visit(node.callee)
		result += "("
		result += visit(node.arguments)
		result += ")"
		return result
	}

	public mutating func visit(_ node: ExprStmtSyntax) -> String {
		visit(node.expr)
	}

	public mutating func visit(_ node: BlockStmtSyntax) -> String {
		node.decls.map { decl in
			indenting {
				$0.visit(decl)
			}
		}.joined(separator: "\n")
	}

	public mutating func visit(_ node: UnaryExprSyntax) -> String {
		visit(node.op) + visit(node.rhs)
	}

	public mutating func visit(_ node: BinaryExprSyntax) -> String {
		visit(node.lhs) + visit(node.op) + visit(node.rhs)
	}

	public mutating func visit(_ node: IdentifierSyntax) -> String {
		node.lexeme
	}

	public mutating func visit(_ node: IntLiteralSyntax) -> String {
		node.lexeme
	}

	public mutating func visit(_ node: ArgumentListSyntax) -> String {
		node.arguments.map {
			visit($0)
		}.joined(separator: ", ")
	}

	public mutating func visit(_ node: FunctionDeclSyntax) -> String {
		var result = "func " + visit(node.name)
		result += "(\(visit(node.parameters)))"
		result += " {\n"
		result += visit(node.body)
		result += "\n}\n"
		return result
	}

	public mutating func visit(_ node: VariableExprSyntax) -> String {
		visit(node.name)
	}

	public mutating func visit(_ node: ParameterListSyntax) -> String {
		node.parameters.map {
			visit($0)
		}.joined(separator: ", ")
	}

	public mutating func visit(_ node: StringLiteralSyntax) -> String {
		node.lexeme
	}

	public mutating func visit(_ node: BinaryOperatorSyntax) -> String {
		" " + node.description + " "
	}

	public mutating func visit(_: StmtSyntax) -> String {
		""
	}

	public mutating func visit(_ node: ErrorSyntax) -> String {
		node.description
	}
}
