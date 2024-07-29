//
//  AnalyzedParamsExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import TalkTalkSyntax

public class AnalyzedParam: Param, AnalyzedExpr {
	public func accept<V>(_: V, _: V.Context) -> V.Value where V: AnalyzedVisitor {
		fatalError("unreachable")
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, context)
	}

	public var name: String { expr.name }
	let expr: any Param

	public var type: ValueType
	public var location: SourceLocation { expr.location }

	public init(type: ValueType, expr: any Param) {
		self.expr = expr
		self.type = type
	}
}

public extension Param where Self == AnalyzedParam {
	static func int(_ name: String) -> AnalyzedParam {
		AnalyzedParam(type: .int, expr: ParamSyntax(name: name, location: [.synthetic(.identifier, lexeme: name)]))
	}
}

public struct AnalyzedParamsExpr: AnalyzedExpr, ParamsExpr {
	public var type: ValueType
	let expr: ParamsExpr

	public var paramsAnalyzed: [AnalyzedParam]
	public var params: [any Param] { expr.params }
	public var location: SourceLocation { expr.location }

	public mutating func infer(from env: Analyzer.Environment) {
		for (i, name) in paramsAnalyzed.enumerated() {
			if let binding = env.infer(name.name) {
				paramsAnalyzed[i].type = binding.type
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
		self.expr = ParamsExprSyntax(
			params: elements.map {
				ParamSyntax(name: $0.name, location: [.synthetic(.identifier, lexeme: $0.name)])
			},
			location: [.synthetic(.identifier)]
		)
		self.paramsAnalyzed = elements
		self.type = .void
	}

	public typealias ArrayLiteralElement = AnalyzedParam
}
