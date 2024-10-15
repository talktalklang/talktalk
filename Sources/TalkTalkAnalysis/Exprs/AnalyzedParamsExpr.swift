//
//  AnalyzedParamsExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

import TalkTalkCore
import TypeChecker

public struct AnalyzedParam: Param, AnalyzedExpr, Typed {
	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, context)
	}

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(wrapped, context)
	}

	public var name: String { wrapped.name }
	public let wrapped: ParamSyntax
	public var analyzedChildren: [any AnalyzedSyntax] { [] }
	public let environment: Environment

	public let inferenceType: InferenceType
	public var type: TypeExprSyntax? { wrapped.type }

	public init(type: InferenceType, wrapped: ParamSyntax, environment: Environment) {
		self.wrapped = wrapped
		self.inferenceType = type
		self.environment = environment
	}

	public var debugDescription: String {
		"\(name): \(inferenceType.debugDescription)"
	}
}

public extension Param where Self == AnalyzedParam {
	static func int(_ name: String, in context: Context) -> AnalyzedParam {
		let t = InferenceType.base(.int)
		return AnalyzedParam(
			type: t,
			wrapped: ParamSyntax(
				id: -3,
				name: name,
				location: [.synthetic(.identifier, lexeme: name)]
			),
			environment: .init(inferenceContext: context, symbolGenerator: .init(moduleName: "", parent: nil))
		)
	}
}

public struct AnalyzedParamsExpr: AnalyzedExpr, ParamsExpr {
	public let inferenceType: InferenceType
	public let wrapped: ParamsExprSyntax

	public var analyzedChildren: [any AnalyzedSyntax] { paramsAnalyzed }
	public var paramsAnalyzed: [AnalyzedParam]
	public var environment: Environment

	public var params: [ParamSyntax] { wrapped.params }
	public var isVarArg = false

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(wrapped, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}
}
