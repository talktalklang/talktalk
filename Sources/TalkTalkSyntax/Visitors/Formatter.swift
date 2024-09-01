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

	public func visit(_ expr: ImportStmtSyntax, _: Context) throws -> String {
		"import \(expr.module.name)"
	}

	public func visit(_ expr: ExprStmtSyntax, _ context: Context) throws -> String {
		try expr.expr.accept(self, context)
	}

	public func visit(_ expr: MemberExprSyntax, _ context: Context) throws -> String {
		var result = try expr.receiver.accept(self, context)
		result += "."
		result += expr.property

		context.lastType = expr

		return result
	}

	public func visit(_ expr: CallArgument, _ context: Context) throws -> String {
		if let label = expr.label {
			try "\(label): \(expr.value.accept(self, context))"
		} else {
			try expr.value.accept(self, context)
		}
	}

	public func visit(_ expr: TypeExprSyntax, _ context: Context) throws -> String {
		var result = expr.identifier.lexeme

		if !expr.genericParams.isEmpty {
			result += "<"
			result += try expr.genericParams.map { try visit($0, context) }.joined(separator: ", ")
			result += ">"
		}

		return result
	}

	public func visit(_ expr: WhileStmtSyntax, _ context: Context) throws -> String {
		var result = "while "
		result += try expr.condition.accept(self, context)
		result += " "
		result += try visit(expr.body.cast(BlockStmtSyntax.self), context)

		context.lastType = expr

		return result
	}

	public func visit(_ expr: BinaryExprSyntax, _ context: Context) throws -> String {
		var result = ""
		result += try expr.lhs.accept(self, context)
		result += " " + expr.op.rawValue + " "
		result += try expr.rhs.accept(self, context)

		context.lastType = expr

		return result
	}

	public func visit(_ expr: ParamSyntax, _ context: Context) throws -> Value {
		context.lastType = expr
		return expr.name
	}

	public func visit(_ expr: GenericParamsSyntax, _ context: Context) throws -> String {
		if expr.params.isEmpty {
			return ""
		}

		var result = "<"
		result += try expr.params.map { try $0.type.accept(self, context) }.joined(separator: ", ")
		result += "> "
		return result
	}

	public func visit(_ expr: IfExprSyntax, _ context: Context) throws -> Value {
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

	public func visit(_ expr: IdentifierExprSyntax, _ context: Context) throws -> String {
		context.lastType = expr

		return "\(expr.name)"
	}

	public func visit(_ expr: DefExprSyntax, _ context: Context) throws -> Value {
		var result = try "\(expr.receiver.accept(self, context)) = "
		result += try expr.value.accept(self, context)

		context.lastType = expr

		return result
	}

	public func visit(_ expr: VarExprSyntax, _ context: Context) throws -> Value {
		context.lastType = expr

		return expr.name
	}

	public func visit(_ expr: UnaryExprSyntax, _ context: Context) throws -> String {
		context.lastType = expr

		return try "\(expr.op)" + expr.expr.accept(self, context)
	}

	public func visit(_ expr: CallExprSyntax, _ context: Context) throws -> Value {
		var result = try expr.callee.accept(self, context)
		result +=
			"(" + expr.args.map { try! $0.value.accept(self, context) }.joined(separator: ", ") + ")"

		context.lastType = expr

		return result
	}

	public func visit(_ expr: FuncExprSyntax, _ context: Context) throws -> Value {
		var result = ""

		if let lastType = context.lastType, !(lastType is FuncExpr), !(lastType is StructExpr) {
			result += "\n"
		}

		result += "func"
		if let name = expr.name {
			result += " " + name.lexeme
		}

		result += try "(" + visit(expr.params.cast(ParamsExprSyntax.self), context) + ") "

		if let typeDecl = expr.typeDecl {
			result += try ("-> " + typeDecl.accept(self, context)) + " "
		}

		result += try visit(expr.body.cast(BlockStmtSyntax.self), context)

		context.lastType = expr

		return result
	}

	public func visit(_ expr: InitDeclSyntax, _ context: Context) throws -> String {
		var result = ""

		result += "init"
		result += try "(" + visit(expr.params.cast(ParamsExprSyntax.self), context) + ") "
		result += try visit(expr.body.cast(BlockStmtSyntax.self), context)

		context.lastType = expr

		return result
	}

	public func visit(_ expr: BlockStmtSyntax, _ context: Context) throws -> Value {
		var result = "{\n"
		result += try indenting {
			var result: [String] = []
			for expr in expr.stmts {
				try result.append(expr.accept($0, context))
			}
			return result.joined(separator: "\n")
		}
		result += "\n}"

		context.lastType = expr

		return result
	}

	public func visit(_ expr: LiteralExprSyntax, _ context: Context) throws -> Value {
		context.lastType = expr

		return switch expr.value {
		case let .int(int):
			"\(int)"
		case let .bool(bool):
			"\(bool)"
		case let .string(string):
			"""
			"\(string)"
			"""
		case .none:
			"none"
		}
	}

	public func visit(_ expr: ParamsExprSyntax, _ context: Context) throws -> Value {
		context.lastType = expr

		return expr.params.map(\.name).joined(separator: ", ")
	}

	public func visit(_ expr: ParseErrorSyntax, _ context: Context) throws -> Value {
		context.lastType = expr

		return "<error: \(expr.message)>"
	}

	public func visit(_ expr: StructExprSyntax, _ context: Context) throws -> String {
		var result = "\nstruct "

		if let name = expr.name {
			result += name
		}

		context.lastType = expr
		result += " "
		result += try expr.body.accept(self, context)

		return result
	}

	public func visit(_ expr: DeclBlockSyntax, _ context: Context) throws -> String {
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

	public func visit(_ expr: VarDeclSyntax, _ context: Context) throws -> String {
		context.lastType = expr

		var result = "var \(expr.name)"

		if let typeExpr = expr.typeExpr {
			result += ": "
			result += try typeExpr.accept(self, context)
		}

		if let value = expr.value {
			result += " = "
			result += try value.accept(self, context)
		}

		return result
	}

	public func visit(_ expr: LetDeclSyntax, _ context: Context) throws -> String {
		var result = "let \(expr.name)"

		if let typeExpr = expr.typeExpr {
			result += ": "
			result += try typeExpr.accept(self, context)
		}

		if let value = expr.value {
			result += " = "
			result += try value.accept(self, context)
		}

		return result
	}

	public func visit(_ expr: ReturnStmtSyntax, _ context: Context) throws -> String {
		context.lastType = expr

		return try "return \(expr.value?.accept(self, context) ?? "")"
	}

	public func visit(_ expr: IfStmtSyntax, _ context: Context) throws -> String {
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

	public func visit(_ expr: StructDeclSyntax, _ context: Context) throws -> String {
		var result = "\nstruct "

		result += expr.name

		context.lastType = expr
		result += " "
		result += try expr.body.accept(self, context)

		return result
	}

	public func visit(_ expr: ArrayLiteralExprSyntax, _ context: Context) throws -> String {
		try "[" + expr.exprs.map({ try $0.accept(self, context) }).joined(separator: ", ") + "]"
	}

	public func visit(_ expr: SubscriptExprSyntax, _ context: Context) throws -> String {
		let result = try expr.receiver.accept(self, context)
		let args = try expr.args.map({ try $0.accept(self, context) }).joined(separator: ", ")
		return result + "[\(args)]"
	}

	public func visit(_ expr: DictionaryLiteralExprSyntax, _ context: Context) throws -> String {
		var result = "["
		result += try expr.elements.map { try $0.accept(self, context) }.joined(separator: ", ")
		return result + "]"
	}

	public func visit(_ expr: DictionaryElementExprSyntax, _ context: Context) throws -> String {
		var result = try expr.key.accept(self, context)
		result += ": "
		result += try expr.value.accept(self, context)
		return result
	}

	public func visit(_ expr: ProtocolDeclSyntax, _ context: Context) throws -> String {
		return "(typeName)"
	}

	public func visit(_ expr: ProtocolBodyDeclSyntax, _ context: Context) throws -> String {
		return "(typeName)"
	}

	public func visit(_ expr: FuncSignatureDeclSyntax, _ context: Context) throws -> String {
		return "(typeName)"
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
