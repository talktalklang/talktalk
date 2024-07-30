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
		return component ?? ""
	}

	static func buildEither(first component: String) -> String {
		return component
	}

	static func buildEither(second component: String) -> String {
		return component
	}

	static func buildArray(_ components: [String]) -> String {
		components.joined(separator: "\n")
	}
}

public struct ASTPrinter: Visitor {
	public struct Context {}
	public typealias Value = String

	var indentLevel = 0

	public static func format(_ exprs: [any Expr]) -> String {
		let formatter = ASTPrinter()
		let context = Context()
		let result = exprs.map { $0.accept(formatter, context) }
		return result.map { line in
			line.replacing(#/(\t+)(\d+) │ /#, with: {
				// Tidy indents
				"\($0.output.2) |\($0.output.1)└ "
			}).replacing(#/(\t*)(\d+)[\s]*\|/#, with: {
				// Tidy line numbers
				$0.output.2.trimmingCharacters(in: .whitespacesAndNewlines).padding(toLength: 4, withPad: " ", startingAt: 0) + "| \($0.output.1)"
			})

		}.joined(separator: "\n")
	}

	func add(@StringBuilder _ content: () -> String) -> String {
		content()
			.components(separatedBy: .newlines)
			.filter { $0.trimmingCharacters(in: .whitespacesAndNewlines) != "" }
			.map {
				String(repeating: "\t", count: indentLevel) + $0
			}.joined(separator: "\n")
	}

	func dump(_ expr: any Syntax, _ extra: String = "") -> String {
		"\(expr.location.start.line) | \(type(of: expr)) ln: \(expr.location.start.line) col: \(expr.location.start.column) \(extra)"
	}

	func indent(@StringBuilder _ content: () -> String) -> String {
		var copy = ASTPrinter()
		copy.indentLevel = indentLevel + 1
		return copy.add(content)
	}

	@StringBuilder public func visit(_ expr: any MemberExpr, _ context: Context) -> String {
		dump(expr, "property: \(expr.property)")
		indent {
			expr.receiver.accept(self, context)
		}
}

	@StringBuilder public func visit(_ expr: any CallExpr, _ context: Context) -> String {
		dump(expr)
		indent {
			expr.callee.accept(self, context)
			if !expr.args.isEmpty {
				indent {
					expr.args.map { $0.value.accept(self, context) }.joined(separator: "\n")
				}
			}
		}
	}

	@StringBuilder public func visit(_ expr: any DefExpr, _ context: Context) -> String {
		dump(expr, "name: \(expr.name.lexeme)")
		indent {
			expr.value.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: ErrorSyntax, _ context: Context) -> String {
		dump(expr, expr.message)
	}

	@StringBuilder public func visit(_ expr: any LiteralExpr, _ context: Context) -> String {
		dump(expr, "value: \(expr.value)")
	}

	@StringBuilder public func visit(_ expr: any VarExpr, _ context: Context) -> String {
		dump(expr, "name: \(expr.name)")
	}

	@StringBuilder public func visit(_ expr: any BinaryExpr, _ context: Context) -> String {
		dump(expr, "op: \(expr.op)")
		indent {
			expr.lhs.accept(self, context)
			expr.rhs.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: any IfExpr, _ context: Context) -> String {
		dump(expr)
		indent {
			expr.condition.accept(self, context)
			indent {
				expr.consequence.accept(self, context)
				expr.alternative.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: any WhileExpr, _ context: Context) -> String {
		dump(expr)
		indent {
			expr.condition.accept(self, context)
			indent {
				expr.body.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: any BlockExpr, _ context: Context) -> String {
		dump(expr)
		indent {
			expr.exprs.map { $0.accept(self, context) }.joined(separator: "\n")
		}
	}

	@StringBuilder public func visit(_ expr: any FuncExpr, _ context: Context) -> String {
		dump(expr, "params: \(expr.params.params.map(\.description))")
		visit(expr.body, context)
	}

	@StringBuilder public func visit(_ expr: any ParamsExpr, _ context: Context) -> String {
		dump(expr)
		indent {
			expr.params.map { $0.accept(self, context) }.joined(separator: "\n")
		}
	}

	@StringBuilder public func visit(_ expr: any Param, _ context: Context) -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: any StructExpr, _ context: Context) -> String {
		dump(expr)
		indent {
			expr.body.accept(self, context)
		}
	}

	@StringBuilder public func visit(_ expr: any DeclBlockExpr, _ context: Context) -> String {
		dump(expr)
		indent {
			for decl in expr.decls {
				decl.accept(self, context)
			}
		}
	}

	@StringBuilder public func visit(_ expr: any VarDecl, _ context: Context) -> String {
		dump(expr, "name: \(expr.name), type: \(expr.typeDecl)")
	}
}
