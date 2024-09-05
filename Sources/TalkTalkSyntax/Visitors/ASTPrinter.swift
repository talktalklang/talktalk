//
//  ASTPrinter.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

@resultBuilder struct StringBuilder {
	static func buildBlock(_ strings: String...) -> String {
		strings.joined(separator: "\n")
	}

	static func buildOptional(_ component: String?) -> String {
		component ?? ""
	}

	static func buildEither(first component: String) -> String {
		component
	}

	static func buildEither(second component: String) -> String {
		component
	}

	static func buildArray(_ components: [String]) -> String {
		components.joined(separator: "\n")
	}
}

public struct ASTPrinter: Visitor {
	public struct Context {}
	public typealias Value = String

	var indentLevel = 0

	public static func format(_ exprs: [any Syntax]) throws -> String {
		let formatter = ASTPrinter()
		let context = Context()
		let result = try exprs.map { try $0.accept(formatter, context) }
		return result.map { line in
			line.replacing(
				#/(\t+)(\d+) │ /#,
				with: {
					// Tidy indents
					"\($0.output.2) |\($0.output.1)└ "
				}
			).replacing(
				#/(\t*)(\d+)[\s]*\|/#,
				with: {
					// Tidy line numbers
					$0.output.2.trimmingCharacters(in: .whitespacesAndNewlines).padding(
						toLength: 4, withPad: " ", startingAt: 0
					) + "| \($0.output.1)"
				}
			)

		}.joined(separator: "\n")
	}

	func add(@StringBuilder _ content: () throws -> String) -> String {
		do {
			return try content()
				.components(separatedBy: .newlines)
				.filter { $0.trimmingCharacters(in: .whitespacesAndNewlines) != "" }
				.map {
					String(repeating: "\t", count: indentLevel) + $0
				}.joined(separator: "\n")
		} catch {
			return "Error: \(error)"
		}
	}

	func dump(_ expr: any Syntax, _ extra: String = "") -> String {
		"\(expr.location.start.line) | \(type(of: expr)) ln: \(expr.location.start.line) col: \(expr.location.start.column) \(extra)"
	}

	func indent(@StringBuilder _ content: () throws -> String) -> String {
		var copy = ASTPrinter()
		copy.indentLevel = indentLevel + 1
		return copy.add(content)
	}

	@StringBuilder public func visit(_ expr: ImportStmtSyntax, _: Context) throws -> String {
		dump(expr, "module: \(expr.module.name)")
	}

	@StringBuilder public func visit(_ expr: ExprStmtSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			for child in expr.children {
				try child.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: TypeExprSyntax, _: Context) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: UnaryExprSyntax, _ context: Context) throws -> String {
		dump(expr, "op: \(expr.op)")
		indent {
			try expr.expr.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: InitDeclSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.params.accept(self, context)
			try expr.body.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: GenericParamsSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			for param in expr.params {
				try param.type.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: MemberExprSyntax, _ context: Context) throws -> String {
		dump(expr, "property: \(expr.property)")
		indent {
			try expr.receiver.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: CallExprSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.callee.accept(self, context)
			if !expr.args.isEmpty {
				indent {
					try expr.args.map { try $0.value.accept(self, context) }.joined(separator: "\n")
				}
			}
		}
	}

	@StringBuilder public func visit(_ expr: CallArgument, _ context: Context) throws -> String {
		dump(expr, "name: \(expr.label?.lexeme ?? "<none>")")
		indent {
			try expr.value.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: DefExprSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.receiver.accept(self, context)
			try expr.value.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: IdentifierExprSyntax, _: Context) throws -> String {
		dump(expr, "name: \(expr.name)")
	}

	@StringBuilder public func visit(_ expr: ParseErrorSyntax, _: Context) throws -> String {
		dump(expr, expr.message)
	}

	@StringBuilder public func visit(_ expr: LiteralExprSyntax, _: Context) throws -> String {
		dump(expr, "value: \(expr.value)")
	}

	@StringBuilder public func visit(_ expr: VarExprSyntax, _: Context) throws -> String {
		dump(expr, "name: \(expr.name)")
	}

	@StringBuilder public func visit(_ expr: BinaryExprSyntax, _ context: Context) throws -> String {
		dump(expr, "op: \(expr.op)")
		indent {
			try expr.lhs.accept(self, context)
			try expr.rhs.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: IfExprSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.condition.accept(self, context)
			indent {
				try expr.consequence.accept(self, context)
				try expr.alternative.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: WhileStmtSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.condition.accept(self, context)
			indent {
				try expr.body.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: BlockStmtSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.stmts.map { try $0.accept(self, context) }.joined(separator: "\n")
		}
	}

	@StringBuilder public func visit(_ expr: FuncExprSyntax, _ context: Context) throws -> String {
		dump(expr, "params: \(expr.params.params.map(\.description))")
		try visit(expr.body.cast(BlockStmtSyntax.self), context)
	}

	@StringBuilder public func visit(_ expr: ParamsExprSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.params.map { try $0.accept(self, context) }.joined(separator: "\n")
		}
	}

	@StringBuilder public func visit(_ expr: ParamSyntax, _: Context) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: StructExprSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.body.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: DeclBlockSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			for decl in expr.decls {
				try decl.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: VarDeclSyntax, _ context: Context) throws -> String {
		try dump(expr, "name: \(expr.name), type: \(expr.typeExpr?.accept(self, context) ?? "<not specified>")")
	}

	@StringBuilder public func visit(_ expr: LetDeclSyntax, _ context: Context) throws -> String {
		try dump(expr, "name: \(expr.name), type: \(expr.typeExpr?.accept(self, context) ?? "<not specified>")")
	}

	@StringBuilder public func visit(_ expr: ReturnStmtSyntax, _ context: Context) throws -> String {
		dump(expr)
		if let value = expr.value {
			indent {
				try value.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: IfStmtSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			for child in expr.children {
				try child.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: StructDeclSyntax, _ context: Context) throws -> String {
		dump(expr)
		indent {
			for child in expr.children {
				try child.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: ArrayLiteralExprSyntax, _ context: Context) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: SubscriptExprSyntax, _ context: Context) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: DictionaryLiteralExprSyntax, _ context: Context) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: DictionaryElementExprSyntax, _ context: Context) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: ProtocolDeclSyntax, _ context: Context) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: ProtocolBodyDeclSyntax, _ context: Context) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: FuncSignatureDeclSyntax, _ context: Context) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: EnumDeclSyntax, _ context: Context) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: EnumCaseDeclSyntax, _ context: Context) throws -> String {
		dump(expr)
	}

	// GENERATOR_INSERTION
}
