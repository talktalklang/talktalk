//
//  AnalyzedParamsExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public struct AnalyzedParam: Param, AnalyzedExpr {
	public func accept<V>(_: V, _: V.Context) -> V.Value where V: AnalyzedVisitor {
		fatalError("unreachable")
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, context)
	}

	public var name: String
	public var type: ValueType
}

public extension Param where Self == AnalyzedParam {
	static func int(_ name: String) -> AnalyzedParam {
		AnalyzedParam(name: name, type: .int)
	}
}

public struct AnalyzedParamsExpr: AnalyzedExpr, ParamsExpr {
	public var type: ValueType
	let expr: ParamsExpr

	public var paramsAnalyzed: [AnalyzedParam]
	public var params: [any Param] { expr.params }

	public mutating func infer(from env: Analyzer.Environment) {
		for (i, name) in paramsAnalyzed.enumerated() {
			if let binding = env.infer(name.name) {
				paramsAnalyzed[i].type = binding.expr.type
			}
		}
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor {
		visitor.visit(self, scope)
	}
}

extension AnalyzedParamsExpr: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: AnalyzedParam...) {
		self.expr = ParamsExprSyntax(params: elements.map { ParamSyntax(name: $0.name) })
		self.paramsAnalyzed = elements
		self.type = .void
	}

	public typealias ArrayLiteralElement = AnalyzedParam
}
