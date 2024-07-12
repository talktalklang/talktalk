public struct ASTPrinter<Root: Syntax>: ASTVisitor {
	public struct Context {
		var indentLevel: Int = 0
	}

	let root: Root
	var indent = 0

	public static func print(_ root: Root) {
		var printer = ASTPrinter(root: root)
		var context = Context()
		root.accept(&printer, context: &context)
	}

	public init(root: Root) {
		self.root = root
	}

	private func describe<T: Syntax>(_ type: T) {
		self.print("\(T.self)(pos: \(type.position), len: \(type.length))")
	}

	private func print(_ string: String) {
		let indentation = String(repeating: "  ", count: indent)
		let indented = string.components(separatedBy: .newlines).map {
			indentation + $0
		}.joined(separator: "\n")

		Swift.print(indented)
	}

	public func indenting(perform: (inout ASTPrinter) -> Void) {
		var copy = self
		copy.indent += 1
		perform(&copy)
	}

	public func visit(_ node: TypeDeclSyntax, context: inout Context) {
		describe(node)
	}

	public mutating func visit(_ node: ArrayLiteralSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.elements, context: &context)
		}
	}

	public mutating func visit(_ node: PropertyAccessExpr, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.receiver, context: &context)
			$0.visit(node.property, context: &context)
		}
	}

	public mutating func visit(_ node: InitDeclSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.parameters, context: &context)
			$0.visit(node.body, context: &context)
		}
	}

	public mutating func visit(_ node: ClassDeclSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.name, context: &context)
			$0.visit(node.body, context: &context)
		}
	}

	public mutating func visit(_ node: UnaryOperator, context: inout Context) {
		describe(node)
		indenting {
			$0.print(node.description)
		}
	}

	public mutating func visit(_ node: any Syntax, context: inout Context) {
		node.accept(&self, context: &context)
	}

	public mutating func visit(_ node: ProgramSyntax, context: inout Context) {
		describe(node)
		indenting {
			for decl in node.decls {
				$0.visit(decl, context: &context)
			}
		}
	}

	public mutating func visit(_ node: LiteralExprSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.print("lexeme: \(node.description)")
		}
	}

	public mutating func visit(_ node: AssignmentExpr, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.lhs, context: &context)
			$0.visit(node.rhs, context: &context)
		}
	}

	public mutating func visit(_ node: IfStmtSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.condition, context: &context)
			$0.visit(node.body, context: &context)
		}
	}

	public mutating func visit(_ node: ReturnStmtSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.value, context: &context)
		}
	}

	public mutating func visit(_ node: WhileStmtSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.condition, context: &context)
			$0.visit(node.body, context: &context)
		}
	}

 public mutating func visit(_ node: GroupExpr, context: inout Context) {
		describe(node)

		indenting {
			$0.visit(node.expr, context: &context)
		}
	}

	public mutating func visit(_ node: VarDeclSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.variable, context: &context)
			if let expr = node.expr {
				$0.visit(expr, context: &context)
			}
		}
	}

	public mutating func visit(_ node: CallExprSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.callee, context: &context)
			$0.visit(node.arguments, context: &context)
		}
	}

	public mutating func visit(_ node: ExprStmtSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.expr, context: &context)
		}
	}

	public mutating func visit(_ node: BlockStmtSyntax, context: inout Context) {
		describe(node)
		indenting {
			for decl in node.decls {
				$0.visit(decl, context: &context)
			}
		}
	}

	public mutating func visit(_ node: UnaryExprSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.op, context: &context)
			$0.visit(node.rhs, context: &context)
		}
	}

	public mutating func visit(_ node: BinaryExprSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.lhs, context: &context)
			$0.visit(node.op, context: &context)
			$0.visit(node.rhs, context: &context)
		}
	}

	public mutating func visit(_ node: IdentifierSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.print("lexeme: \(node.lexeme)")
		}
	}

	public mutating func visit(_ node: IntLiteralSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.print("lexeme: \(node.lexeme)")
		}
	}

	public mutating func visit(_ node: ArgumentListSyntax, context: inout Context) {
		describe(node)
		indenting {
			for arg in node.arguments {
				$0.visit(arg, context: &context)
			}
		}
	}

	public mutating func visit(_ node: FunctionDeclSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.name, context: &context)
			$0.visit(node.parameters, context: &context)
			$0.visit(node.body, context: &context)
		}
	}

	public mutating func visit(_ node: VariableExprSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.visit(node.name, context: &context)
		}
	}

	public mutating func visit(_ node: ParameterListSyntax, context: inout Context) {
		describe(node)
		indenting {
			for parameter in node.parameters {
				$0.visit(parameter, context: &context)
			}
		}
	}

	public mutating func visit(_ node: StringLiteralSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.print("lexeme: \(node.lexeme)")
		}
	}

	public mutating func visit(_ node: BinaryOperatorSyntax, context: inout Context) {
		describe(node)
	}

	public mutating func visit(_: StmtSyntax, context: inout Context) {}

	public mutating func visit(_ node: ErrorSyntax, context: inout Context) {
		describe(node)
		indenting {
			$0.print(node.description)
		}
	}
}
