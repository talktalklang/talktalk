//
//  ErrorSyntax.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public protocol ErrorSyntax: Decl, Expr, Syntax {
	var message: String { get }
}

public struct SyntaxError: ErrorSyntax {
	public let location: SourceLocation
	public let message: String

	public init(location: SourceLocation, message: String) {
		self.location = location
		self.message = message
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, scope)
	}
}
