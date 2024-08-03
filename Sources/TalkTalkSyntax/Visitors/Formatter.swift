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
			try! result.append(expr.accept(formatter, context))
		}
		return result.joined(separator: "\n")
	}

	public func visit(_ expr: any MemberExpr, _ context: Context) throws -> String {
		var result = try expr.receiver.accept(self, context)
		result += "."
		result += expr.property
		return result
	}

	public func visit(_ expr: any WhileExpr, _ context: Context) throws -> String {
		var result = "while "
		result += try expr.condition.accept(self, context)
		result += " "
		result += try visit(expr.body, context)
		return result
	}

	public func visit(_ expr: any BinaryExpr, _ context: Context) throws -> String {
		var result = ""
		result += try expr.lhs.accept(self, context)
		result += " " + expr.op.rawValue + " "
		result += try expr.rhs.accept(self, context)
		return result
	}

	public func visit(_ expr: any Param, _ context: Context) throws -> Value {
		expr.name
	}

	public func visit(_ expr: any IfExpr, _ context: Context) throws -> Value {
		var result = "if "
		result += try expr.condition.accept(self, context)
		result += " "
		result += "{\n"
		result
		return result
	}

	public func visit(_ expr: any DefExpr, _ context: Context) throws -> Value {
		var result = "\(expr.name.lexeme) = "
		result += try expr.value.accept(self, context)
		return result
	}

	public func visit(_ expr: any VarExpr, _ context: Context) throws -> Value {
		expr.name
	}

	public func visit(_ expr: any UnaryExpr, _ context: Context) throws -> String {
		try "\(expr.op)" + expr.expr.accept(self, context)
	}

	public func visit(_ expr: any CallExpr, _ context: Context) throws -> Value {
		var result = try expr.callee.accept(self, context)
		result += "(" + expr.args.map { try! $0.value.accept(self, context) }.joined(separator: ", ") + ")"
		return result
	}

	public func visit(_ expr: any FuncExpr, _ context: Context) throws -> Value {
		var result = "func"
		if let name = expr.name {
			result += " " + name
		}
		result += try "(" + visit(expr.params, context) + ") "
		result += try visit(expr.body, context)
		return result
	}

	public func visit(_ expr: any BlockExpr, _ context: Context) throws -> Value {
		var result = "{\n"
		result += try indenting {
			var result: [String] = []
			for expr in expr.exprs {
				try result.append(expr.accept($0, context))
			}
			return result.joined(separator: "\n")
		}
		result += "\n}"
		return result
	}

	public func visit(_ expr: any LiteralExpr, _ context: Context) throws -> Value {
		switch expr.value {
		case .int(let int):
			"\(int)"
		case .bool(let bool):
			"\(bool)"
		case .string(let string):
			"""
			"\(string)"
			"""
		case .none:
			"none"
		}
	}

	public func visit(_ expr: any ParamsExpr, _ context: Context) throws -> Value {
		expr.params.map(\.name).joined(separator: ", ")
	}

	public func visit(_ expr: ErrorSyntax, _ context: Context) throws -> Value {
		"<error: \(expr.message)>"
	}

	public func visit(_ expr: any StructExpr, _ context: Context) throws -> String {
		var result = "struct "

		if let name = expr.name {
			result += name
		}

		result += " "
		result += try expr.body.accept(self, context)
		return result
	}

	public func visit(_ expr: any DeclBlockExpr, _ context: Context) throws -> String {
		var result = "{\n"
		result += try indenting {
			var result: [String] = []
			for expr in expr.decls {
				try result.append(expr.accept($0, context))
			}
			return result.joined(separator: "\n")
		}
		result += "\n}"
		return result
	}

	public func visit(_ expr: any VarDecl, _ context: Context) throws -> String {
		"var \(expr.name): \(expr.typeDecl)"
	}

	public func visit(_ expr: any ReturnExpr, _ context: Context) throws -> String {
		"return \(try expr.value?.accept(self, context) ?? "")"
	}

	// MARK: Helpers

	public func indenting(perform: (inout Formatter) throws -> String) rethrows -> String {
		var copy = self
		copy.indent += 1
		let indentation = String(repeating: "\t", count: copy.indent)
		return try perform(&copy).components(separatedBy: .newlines).map {
			indentation + $0
		}.joined(separator: "\n")
	}
}
