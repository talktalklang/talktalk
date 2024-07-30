import Foundation

public struct Formatter: Visitor {
	public struct Context {}
	public typealias Value = String

	var indent = 0

	public static func format(_ input: String) -> String {
		let parsed = Parser.parse(input)
		let formatter = Formatter()
		let context = Formatter.Context()
		var result: [String] = []
		for expr in parsed {
			result.append(expr.accept(formatter, context))
		}
		return result.joined(separator: "\n")
	}

	public func visit(_ expr: any WhileExpr, _ context: Context) -> String {
		var result = "while "
		result += expr.condition.accept(self, context)
		result += " "
		result += visit(expr.body, context)
		return result
	}

	public func visit(_ expr: any BinaryExpr, _ context: Context) -> String {
		var result = ""
		result += expr.lhs.accept(self, context)
		result += " " + expr.op.rawValue + " "
		result += expr.rhs.accept(self, context)
		return result
	}

	public func visit(_ expr: any Param, _ context: Context) -> Value {
		expr.name
	}

	public func visit(_ expr: any IfExpr, _ context: Context) -> Value {
		var result = "if "
		result += expr.condition.accept(self, context)
		result += " "
		result += "{\n"
		return result
	}

	public func visit(_ expr: any DefExpr, _ context: Context) -> Value {
		var result = "\(expr.name.lexeme) = "
		result += expr.value.accept(self, context)
		return result
	}

	public func visit(_ expr: any VarExpr, _ context: Context) -> Value {
		expr.name
	}

	public func visit(_ expr: any CallExpr, _ context: Context) -> Value {
		var result = expr.callee.accept(self, context)
		result += "(" + expr.args.map { $0.accept(self, context) }.joined(separator: ", ") + ")"
		return result
	}

	public func visit(_ expr: any FuncExpr, _ context: Context) -> Value {
		var result = "func"
		if let name = expr.name {
			result += " " + name
		}
		result += "(" + visit(expr.params, context) + ") "
		result += visit(expr.body, context)
		return result
	}

	public func visit(_ expr: any BlockExpr, _ context: Context) -> Value {
		var result = "{\n"
		result += indenting {
			var result: [String] = []
			for expr in expr.exprs {
				result.append(expr.accept($0, context))
			}
			return result.joined(separator: "\n")
		}
		result += "\n}"
		return result
	}

	public func visit(_ expr: any LiteralExpr, _ context: Context) -> Value {
		switch expr.value {
		case .int(let int):
			"\(int)"
		case .bool(let bool):
			"\(bool)"
		case .none:
			"none"
		}
	}

	public func visit(_ expr: any ParamsExpr, _ context: Context) -> Value {
		expr.params.map(\.name).joined(separator: ", ")
	}

	public func visit(_ expr: ErrorSyntax, _ context: Context) -> Value {
		"<error: \(expr.message)>"
	}

	public func visit(_ expr: any StructExpr, _ context: Context) -> String {
		var result = "struct"

		if let name = expr.name {
			result += name
		}

		result += " "
		result += expr.body.accept(self, context)
		return result
	}

	public func visit(_ expr: any DeclBlockExpr, _ context: Context) -> String {
		var result = "{\n"
		result += indenting {
			var result: [String] = []
			for expr in expr.decls {
				result.append(expr.accept($0, context))
			}
			return result.joined(separator: "\n")
		}
		result += "\n}"
		return result
	}

	public func visit(_ expr: any VarDecl, _ context: Context) -> String {
		"var \(expr.name): \(expr.typeDecl)"
	}

	// MARK: Helpers

	public func indenting(perform: (inout Formatter) -> String) -> String {
		var copy = self
		copy.indent += 1
		let indentation = String(repeating: "\t", count: copy.indent)
		return perform(&copy).components(separatedBy: .newlines).map {
			indentation + $0
		}.joined(separator: "\n")
	}
}
