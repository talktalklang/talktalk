public struct ASTPrinter<Root: Syntax>: ASTVisitor {
	public struct Context {
		var indentLevel: Int = 0
	}

	let root: Root
	var indent = 0

	public static func print(_ root: Root) {
		let printer = ASTPrinter(root: root)
		let context = Context()
		root.accept(printer, context: context)
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

	public func visit(_ node: LetDeclSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.variable, context: context)
			if let typeDecl = node.typeDecl {
				$0.visit(typeDecl, context: context)
			}

			if let expr = node.expr {
				$0.visit(expr, context: context)
			}
		}
	}

	public func visit(_ node: IfExprSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.condition, context: context)
			$0.visit(node.thenBlock, context: context)
			$0.visit(node.elseBlock, context: context)
		}
	}

	public func visit(_ node: PropertyDeclSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.name, context: context)
			$0.visit(node.typeDecl, context: context)
		}
	}

	public func visit(_ node: TypeDeclSyntax, context _: Context) {
		describe(node)
	}

	public func visit(_ node: ArrayLiteralSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.elements, context: context)
		}
	}

	public func visit(_ node: PropertyAccessExpr, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.receiver, context: context)
			$0.visit(node.property, context: context)
		}
	}

	public func visit(_ node: InitDeclSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.parameters, context: context)
			$0.visit(node.body, context: context)
		}
	}

	public func visit(_ node: ClassDeclSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.name, context: context)
			$0.visit(node.body, context: context)
		}
	}

	public func visit(_ node: UnaryOperator, context _: Context) {
		describe(node)
		indenting {
			$0.print(node.description)
		}
	}

	public func visit(_ node: any Syntax, context: Context) {
		node.accept(self, context: context)
	}

	public func visit(_ node: ProgramSyntax, context: Context) {
		describe(node)
		indenting {
			for decl in node.decls {
				$0.visit(decl, context: context)
			}
		}
	}

	public func visit(_ node: LiteralExprSyntax, context _: Context) {
		describe(node)
		indenting {
			$0.print("lexeme: \(node.description)")
		}
	}

	public func visit(_ node: AssignmentExpr, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.lhs, context: context)
			$0.visit(node.rhs, context: context)
		}
	}

	public func visit(_ node: IfStmtSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.condition, context: context)
			$0.visit(node.body, context: context)
		}
	}

	public func visit(_ node: ReturnStmtSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.value, context: context)
		}
	}

	public func visit(_ node: WhileStmtSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.condition, context: context)
			$0.visit(node.body, context: context)
		}
	}

	public func visit(_ node: GroupExpr, context: Context) {
		describe(node)

		indenting {
			$0.visit(node.expr, context: context)
		}
	}

	public func visit(_ node: VarDeclSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.variable, context: context)
			if let expr = node.expr {
				$0.visit(expr, context: context)
			}
		}
	}

	public func visit(_ node: CallExprSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.callee, context: context)
			$0.visit(node.arguments, context: context)
		}
	}

	public func visit(_ node: ExprStmtSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.expr, context: context)
		}
	}

	public func visit(_ node: BlockStmtSyntax, context: Context) {
		describe(node)
		indenting {
			for decl in node.decls {
				$0.visit(decl, context: context)
			}
		}
	}

	public func visit(_ node: UnaryExprSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.op, context: context)
			$0.visit(node.rhs, context: context)
		}
	}

	public func visit(_ node: BinaryExprSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.lhs, context: context)
			$0.visit(node.op, context: context)
			$0.visit(node.rhs, context: context)
		}
	}

	public func visit(_ node: IdentifierSyntax, context _: Context) {
		describe(node)
		indenting {
			$0.print("lexeme: \(node.lexeme)")
		}
	}

	public func visit(_ node: IntLiteralSyntax, context _: Context) {
		describe(node)
		indenting {
			$0.print("lexeme: \(node.lexeme)")
		}
	}

	public func visit(_ node: ArgumentListSyntax, context: Context) {
		describe(node)
		indenting {
			for arg in node.arguments {
				$0.visit(arg, context: context)
			}
		}
	}

	public func visit(_ node: FunctionDeclSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.name, context: context)
			$0.visit(node.parameters, context: context)
			$0.visit(node.body, context: context)
		}
	}

	public func visit(_ node: VariableExprSyntax, context: Context) {
		describe(node)
		indenting {
			$0.visit(node.name, context: context)
		}
	}

	public func visit(_ node: ParameterListSyntax, context: Context) {
		describe(node)
		indenting {
			for parameter in node.parameters {
				$0.visit(parameter, context: context)
			}
		}
	}

	public func visit(_ node: StringLiteralSyntax, context _: Context) {
		describe(node)
		indenting {
			$0.print("lexeme: \(node.lexeme)")
		}
	}

	public func visit(_ node: BinaryOperatorSyntax, context _: Context) {
		describe(node)
	}

	public func visit(_: StmtSyntax, context _: Context) {}

	public func visit(_ node: ErrorSyntax, context _: Context) {
		describe(node)
		indenting {
			$0.print(node.description)
		}
	}
}
