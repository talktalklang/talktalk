import Foundation

public struct Formatter: Visitor {
	public class Context {
		var lastType: (any Syntax)? = nil
	}
	public typealias Value = String

	var indent = 0

	public static func format(_ input: String) throws -> String {
		let parsed = try Parser.parse(SourceFile(path: "", text: input))
		let formatter = Formatter()
		let context = Formatter.Context()

		var result: [String] = []
		for expr in parsed {
			try! result.append(expr.accept(formatter, context))
		}

		return result.joined(separator: "\n")
	}

	public func visit(_ expr: any ImportStmt, _ context: Context) throws -> String {
		"import \(expr.module.name)"
	}

	public func visit(_ expr: any ExprStmt, _ context: Context) throws -> String {
		try expr.expr.accept(self, context)
	}

	public func visit(_ expr: any MemberExpr, _ context: Context) throws -> String {
		var result = try expr.receiver.accept(self, context)
		result += "."
		result += expr.property

		context.lastType = expr

		return result
	}

	public func visit(_ expr: any TypeExpr, _ context: Context) throws -> String {
		var result = expr.identifier.lexeme
		if let genericParams = expr.genericParams {
			result += try visit(genericParams, context)
		}
		return result
	}

	public func visit(_ expr: any WhileStmt, _ context: Context) throws -> String {
		var result = "while "
		result += try expr.condition.accept(self, context)
		result += " "
		result += try visit(expr.body, context)

		context.lastType = expr

		return result
	}

	public func visit(_ expr: any BinaryExpr, _ context: Context) throws -> String {
		var result = ""
		result += try expr.lhs.accept(self, context)
		result += " " + expr.op.rawValue + " "
		result += try expr.rhs.accept(self, context)

		context.lastType = expr

		return result
	}

	public func visit(_ expr: any Param, _ context: Context) throws -> Value {
		context.lastType = expr
		return expr.name
	}

	public func visit(_ expr: any GenericParams, _ context: Context) throws -> String {
		if expr.params.isEmpty {
			return ""
		}

		var result = "<"
		result += expr.params.map(\.name).joined(separator: ", ")
		result += "> "
		return result
	}

	public func visit(_ expr: any IfExpr, _ context: Context) throws -> Value {
		var result = "if "
		result += try expr.condition.accept(self, context)
		result += " "
		result += try indenting {
			try expr.consequence.accept($0, context)
		}
		result += " else "
		result += try indenting {
			try expr.alternative.accept($0, context)
		}

		context.lastType = expr

		return result
	}

	public func visit(_ expr: any IdentifierExpr, _ context: Context) throws -> String {
		context.lastType = expr

		return "\(expr.name)"
	}

	public func visit(_ expr: any DefExpr, _ context: Context) throws -> Value {
		var result = "\(try expr.receiver.accept(self, context)) = "
		result += try expr.value.accept(self, context)

		context.lastType = expr

		return result
	}

	public func visit(_ expr: any VarExpr, _ context: Context) throws -> Value {
		context.lastType = expr

		return expr.name
	}

	public func visit(_ expr: any UnaryExpr, _ context: Context) throws -> String {
		context.lastType = expr

		return try "\(expr.op)" + expr.expr.accept(self, context)
	}

	public func visit(_ expr: any CallExpr, _ context: Context) throws -> Value {
		var result = try expr.callee.accept(self, context)
		result +=
			"(" + expr.args.map { try! $0.value.accept(self, context) }.joined(separator: ", ") + ")"

		context.lastType = expr

		return result
	}

	public func visit(_ expr: any FuncExpr, _ context: Context) throws -> Value {
		var result = ""

		if let lastType = context.lastType, !(lastType is FuncExpr), !(lastType is StructExpr) {
			result += "\n"
		}

		result += "func"
		if let name = expr.name {
			result += " " + name.lexeme
		}
		result += try "(" + visit(expr.params, context) + ") "
		result += try visit(expr.body, context)

		context.lastType = expr

		return result
	}

	public func visit(_ expr: any InitDecl, _ context: Context) throws -> String {
		var result = ""

		result += "init"
		result += try "(" + visit(expr.parameters, context) + ") "
		result += try visit(expr.body, context)

		context.lastType = expr

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

		context.lastType = expr

		return result
	}

	public func visit(_ expr: any LiteralExpr, _ context: Context) throws -> Value {
		context.lastType = expr

		return switch expr.value {
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
		context.lastType = expr

		return expr.params.map(\.name).joined(separator: ", ")
	}

	public func visit(_ expr: ParseError, _ context: Context) throws -> Value {
		context.lastType = expr

		return "<error: \(expr.message)>"
	}

	public func visit(_ expr: any StructExpr, _ context: Context) throws -> String {
		var result = "\nstruct "

		if let name = expr.name {
			result += name
		}

		context.lastType = expr
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

		context.lastType = expr

		return result
	}

	public func visit(_ expr: any VarDecl, _ context: Context) throws -> String {
		context.lastType = expr
		
		var result = "var \(expr.name)"

		if let typeDecl = expr.typeDecl {
			result += ": \(typeDecl)"
		}

		if let value = expr.value {
			result += " = "
			result += try value.accept(self, context)
		}

		return result
	}

	public func visit(_ expr: any LetDecl, _ context: Context) throws -> String {
		var result = "let \(expr.name)"

		if let typeDecl = expr.typeDecl {
			result += ": \(typeDecl)"
		}

		if let value = expr.value {
			result += " = "
			result += try value.accept(self, context)
		}

		return result
	}

	public func visit(_ expr: any ReturnExpr, _ context: Context) throws -> String {
		context.lastType = expr

		return "return \(try expr.value?.accept(self, context) ?? "")"
	}

	public func visit(_ expr: any IfStmt, _ context: Context) throws -> String {
		var result = "if "
		result += try expr.condition.accept(self, context)
		result += " "
		result += try indenting {
			try expr.consequence.accept($0, context)
		}

		if let alternative = expr.alternative {
			result += " else "
			result += try indenting {
				try alternative.accept($0, context)
			}
		}

		context.lastType = expr

		return result
	}


	public func visit(_ expr: any StructDecl, _ context: Context) throws -> String {
		var result = "\nstruct "

		result += expr.name

		context.lastType = expr
		result += " "
		result += try expr.body.accept(self, context)

		return result
	}


	// GENERATOR_INSERTION

	// MARK: Helpers

	public func indenting(perform: (inout Formatter) throws -> String) rethrows -> String {
		var copy = self
		copy.indent += 1
		let indentation = String(repeating: "\t", count: 1)
		return try perform(&copy).components(separatedBy: .newlines).map {
			indentation + $0
		}.joined(separator: "\n")
	}
}
