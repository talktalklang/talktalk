public struct ASTPrinter<Root: Syntax>: ASTVisitor {
	let root: Root
	var indent = 0

	public static func print(_ root: Root) {
		var printer = ASTPrinter(root: root)
		root.accept(&printer)
	}

	public init(root: Root) {
		self.root = root
	}

	private func describe(_ type: any Syntax) {
		print("\(type)(position: \(type.position), length: \(type.length))")
	}

	private func print(_ string: String) {
		let indentation = String(repeating: " ", count: indent)
		Swift.print(indentation + string)
	}

	public func indenting(perform: (inout ASTPrinter) -> Void) {
		var copy = self
		copy.indent += 1
		perform(&copy)
	}

	public mutating func visit(_ node: ProgramSyntax) {
		describe(node)
		indenting {
			for decl in node.decls {
				switch decl {
				case let decl as VarDeclSyntax:
					$0.visit(decl)
				case let decl as FunctionDeclSyntax:
					$0.visit(decl)
				default:
					()
				}
			}
		}
	}

	public mutating func visit(_ node: GroupExpr) {
		describe(node)

		indenting {
			$0.visit(node.expr)
		}
	}

	public mutating func visit(_ node: VarDeclSyntax) {
		describe(node)
		indenting {
			$0.visit(node.variable)
			if let expr = node.expr {
				$0.visit(expr.concrete)
			}
		}
	}

	public mutating func visit(_ node: CallExprSyntax) {
		describe(node)
		indenting {
			$0.visit(node.callee)
			$0.visit(node.arguments)
		}
	}

	public mutating func visit(_ node: ExprStmtSyntax) {
		describe(node)
		indenting {
			$0.visit(node.expr)
		}
	}

	public mutating func visit(_ node: BlockStmtSyntax) {
		describe(node)
		indenting {
			for decl in node.decls {
				$0.visit(decl)
			}
		}
	}

	public mutating func visit(_ node: UnaryExprSyntax) {
		describe(node)
		indenting {
			$0.visit(node.op)
			$0.visit(node.rhs)
		}
	}

	public mutating func visit(_ node: BinaryExprSyntax) {
		describe(node)
		indenting {
			$0.visit(node.lhs)
			$0.visit(node.op)
			$0.visit(node.rhs)
		}
	}

	public mutating func visit(_ node: IdentifierSyntax) {
		describe(node)
		indenting {
			$0.print("lexeme: \(node.lexeme)")
		}
	}

	public mutating func visit(_ node: IntLiteralSyntax) {
		describe(node)
		indenting {
			$0.print("lexeme: \(node.lexeme)")
		}
	}

	public mutating func visit(_ node: ArgumentListSyntax) {
		describe(node)
		indenting {
			for arg in node.arguments {
				$0.visit(arg)
			}
		}
	}

	public mutating func visit(_ node: FunctionDeclSyntax) {
		describe(node)
		indenting {
			$0.visit(node.name)
			$0.visit(node.parameters)
			$0.visit(node.body)
		}
	}

	public mutating func visit(_ node: VariableExprSyntax) {
		describe(node)
		indenting {
			$0.visit(node.name)
		}
	}

	public mutating func visit(_ node: ParameterListSyntax) {
		describe(node)
		indenting {
			for parameter in node.parameters {
				$0.visit(parameter)
			}
		}
	}

	public mutating func visit(_ node: StringLiteralSyntax) {
		describe(node)
		indenting {
			$0.print("lexeme: \(node.lexeme)")
		}
	}

	public mutating func visit(_ node: BinaryOperatorSyntax) {
		describe(node)
	}

	public mutating func visit(_ node: StmtSyntax) {
	}

	public mutating func visit(_ node: ErrorSyntax) {
		describe(node)
		indenting {
			$0.print(node.description)
		}
	}
}
