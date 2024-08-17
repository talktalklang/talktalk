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
		try! content()
			.components(separatedBy: .newlines)
			.filter { $0.trimmingCharacters(in: .whitespacesAndNewlines) != "" }
			.map {
				String(repeating: "\t", count: indentLevel) + $0
			}.joined(separator: "\n")
	}

	func dump(_ expr: any Syntax, _ extra: String = "") -> String {
		"\(expr.location.start.line) | \(type(of: expr)) ln: \(expr.location.start.line) col: \(expr.location.start.column) \(extra)"
	}

	func indent(@StringBuilder _ content: () throws -> String) -> String {
		var copy = ASTPrinter()
		copy.indentLevel = indentLevel + 1
		return copy.add(content)
	}

	@StringBuilder public func visit(_ expr: any ImportStmt, _: Context) throws -> String {
		dump(expr, "module: \(expr.module.name)")
	}

	@StringBuilder public func visit(_ expr: any ExprStmt, _ context: Context) throws -> String {
		dump(expr)
		indent {
			for child in expr.children {
				try child.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: any TypeExpr, _: Context) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: any UnaryExpr, _ context: Context) throws -> String {
		dump(expr, "op: \(expr.op)")
		indent {
			try expr.expr.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: any InitDecl, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.parameters.accept(self, context)
			try expr.body.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: any GenericParams, _: Context) throws -> String {
		dump(expr)
		indent {
			for param in expr.params {
				param.name
			}
		}
	}

	@StringBuilder public func visit(_ expr: any MemberExpr, _ context: Context) throws -> String {
		dump(expr, "property: \(expr.property)")
		indent {
			try expr.receiver.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: any CallExpr, _ context: Context) throws -> String {
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

	@StringBuilder public func visit(_ expr: any DefExpr, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.receiver.accept(self, context)
			try expr.value.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: any IdentifierExpr, _: Context) throws -> String {
		dump(expr, "name: \(expr.name)")
	}

	@StringBuilder public func visit(_ expr: ParseError, _: Context) throws -> String {
		dump(expr, expr.message)
	}

	@StringBuilder public func visit(_ expr: any LiteralExpr, _: Context) throws -> String {
		dump(expr, "value: \(expr.value)")
	}

	@StringBuilder public func visit(_ expr: any VarExpr, _: Context) throws -> String {
		dump(expr, "name: \(expr.name)")
	}

	@StringBuilder public func visit(_ expr: any BinaryExpr, _ context: Context) throws -> String {
		dump(expr, "op: \(expr.op)")
		indent {
			try expr.lhs.accept(self, context)
			try expr.rhs.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: any IfExpr, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.condition.accept(self, context)
			indent {
				try expr.consequence.accept(self, context)
				try expr.alternative.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: any WhileStmt, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.condition.accept(self, context)
			indent {
				try expr.body.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: any BlockStmt, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.stmts.map { try $0.accept(self, context) }.joined(separator: "\n")
		}
	}

	@StringBuilder public func visit(_ expr: any FuncExpr, _ context: Context) throws -> String {
		dump(expr, "params: \(expr.params.params.map(\.description))")
		try visit(expr.body, context)
	}

	@StringBuilder public func visit(_ expr: any ParamsExpr, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.params.map { try $0.accept(self, context) }.joined(separator: "\n")
		}
	}

	@StringBuilder public func visit(_ expr: any Param, _: Context) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: any StructExpr, _ context: Context) throws -> String {
		dump(expr)
		indent {
			try expr.body.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: any DeclBlock, _ context: Context) throws -> String {
		dump(expr)
		indent {
			for decl in expr.decls {
				try decl.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: any VarDecl, _: Context) throws -> String {
		dump(expr, "name: \(expr.name), type: \(expr.typeDecl ?? "<no type decl>")")
	}

	@StringBuilder public func visit(_ expr: any LetDecl, _: Context) throws -> String {
		dump(expr, "name: \(expr.name), type: \(expr.typeDecl ?? "<no type decl>")")
	}

	@StringBuilder public func visit(_ expr: any ReturnExpr, _ context: Context) throws -> String {
		dump(expr)
		if let value = expr.value {
			indent {
				try value.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: any IfStmt, _ context: Context) throws -> String {
		dump(expr)
		indent {
			for child in expr.children {
				try child.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: any StructDecl, _ context: Context) throws -> String {
		dump(expr)
		indent {
			for child in expr.children {
				try child.accept(self, context)
			}
		}
	}

	// GENERATOR_INSERTION
}
