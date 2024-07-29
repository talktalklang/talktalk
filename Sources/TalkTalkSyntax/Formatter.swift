import Foundation

public struct Formatter: Visitor {
	public struct Context {
		public init() {}
	}
	public typealias Value = String

	var indent = 0

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
		result += expr.op.rawValue
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
		var result = "\(expr.name) = "
		result += expr.value.accept(self, context)
		return result
	}

	public func visit(_ expr: any VarExpr, _ context: Context) -> Value {
		""
	}

	public func visit(_ expr: any CallExpr, _ context: Context) -> Value {
		""
	}

	public func visit(_ expr: any FuncExpr, _ context: Context) -> Value {
		""
	}

	public func visit(_ expr: any BlockExpr, _ context: Context) -> Value {
		""
	}

	public func visit(_ expr: any LiteralExpr, _ context: Context) -> Value {
		""
	}

	public func visit(_ expr: any ParamsExpr, _ context: Context) -> Value {
		""
	}
	public func visit(_ expr: any ErrorExpr, _ context: Context) -> Value {
		""
	}

	// MARK: Helpers

	public mutating func indenting(perform: (inout Formatter) -> String) -> String {
		var copy = self
		copy.indent += 1
		let indentation = String(repeating: "\t", count: copy.indent)
		return perform(&copy).components(separatedBy: .newlines).map {
			indentation + $0
		}.joined(separator: "\n")
	}
}
