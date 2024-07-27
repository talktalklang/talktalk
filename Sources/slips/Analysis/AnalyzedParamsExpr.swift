//
//  AnalyzedParamsExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public struct AnalyzedParam: Param, AnalyzedExpr {
	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V : AnalyzedVisitor {
		fatalError("unreachable")
	}
	
	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V : Visitor {
		fatalError("unreachable")
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

	public var namesAnalyzed: [AnalyzedParam]
	public var names: [any Param] { expr.names }

	public mutating func infer(from env: Analyzer.Environment) {
		for (i, name) in namesAnalyzed.enumerated() {
			if let expr = env.lookup(name.name) {
				namesAnalyzed[i].type = expr.type
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
