//
//  GenericParams.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

public protocol GenericParam {
	var type: any TypeExpr { get }
}

public struct GenericParamSyntax: GenericParam {
	public var type: any TypeExpr
}

public protocol GenericParams: Syntax {
	var params: [any GenericParam] { get }
}

public extension GenericParams {
	var isEmpty: Bool { params.isEmpty }
	var count: Int { params.count }
}

public struct GenericParamsSyntax: GenericParams {
	public var id: SyntaxID
	public var params: [GenericParam]
	public var location: SourceLocation
	public var children: [any Syntax] { [] }

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, context)
	}
}
