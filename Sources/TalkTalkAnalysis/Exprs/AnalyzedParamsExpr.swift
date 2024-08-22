//
//  AnalyzedParamsExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import TalkTalkSyntax

public class AnalyzedParam: Param, AnalyzedExpr, Typed {
	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, context)
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, context)
	}

	public var name: String { expr.name }
	let expr: any Param
	public var analyzedChildren: [any AnalyzedSyntax] { [] }
	public let environment: Environment

	public let typeID: TypeID
	public var type: (any TypeExpr)? { expr.type }

	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public init(type: TypeID, expr: any Param, environment: Environment) {
		self.expr = expr
		self.typeID = type
		self.environment = environment
	}

	public var debugDescription: String {
		"\(name): \(typeID.current.description)"
	}
}

public extension Param where Self == AnalyzedParam {
	static func int(_ name: String) -> AnalyzedParam {
		let t = TypeID()
		t.update(.int)
		return AnalyzedParam(type: t, expr: ParamSyntax(name: name, location: [.synthetic(.identifier, lexeme: name)]), environment: .init(symbolGenerator: .init(moduleName: "", parent: nil)))
	}
}

public struct AnalyzedParamsExpr: AnalyzedExpr, ParamsExpr {
	public let typeID: TypeID
	let expr: ParamsExpr

	public var analyzedChildren: [any AnalyzedSyntax] { paramsAnalyzed }
	public var paramsAnalyzed: [AnalyzedParam]
	public var environment: Environment

	public var params: [any Param] { expr.params }
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public var isVarArg = false

	public mutating func infer(from env: Environment) {
		for (i, name) in paramsAnalyzed.enumerated() {
			if let binding = env.infer(name.name) {
				let typeID = paramsAnalyzed[i].typeID
				typeID.update(binding.type.type())
			}
		}
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
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
		self.typeID = TypeID()
		self.environment = if let element = elements.first {
			element.environment
		} else {
			.init(symbolGenerator: .init(moduleName: "", parent: nil))
		}
	}

	public var isEmpty: Bool { params.isEmpty }

	public typealias ArrayLiteralElement = AnalyzedParam
}
