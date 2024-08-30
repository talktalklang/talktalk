//
//  DeclBlock.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/28/24.
//

public protocol DeclBlock: Expr {
	var decls: [any Syntax] { get }
}

public struct DeclBlockSyntax: DeclBlock {
	public var id: SyntaxID
	public var decls: [any Syntax]
	public let location: SourceLocation
	public var children: [any Syntax] { decls }

	public init(id: SyntaxID, decls: [any Syntax], location: SourceLocation) {
		self.id = id
		self.decls = decls
		self.location = location
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
