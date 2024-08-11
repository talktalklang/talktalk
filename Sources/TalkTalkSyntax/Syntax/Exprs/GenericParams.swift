//
//  GenericParams.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

public protocol GenericParam {
	var name: String { get }
}

public struct GenericParamSyntax: GenericParam {
	public var name: String
}

public protocol GenericParams: Syntax {
	var params: [any GenericParam] { get }
}

public struct GenericParamsSyntax: GenericParams {
	public var params: [GenericParam]
	public var location: SourceLocation
	public var children: [any Syntax] { [] }

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, context)
	}
}
