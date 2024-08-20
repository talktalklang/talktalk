//
//  CallExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public struct CallArgument: Syntax {
	public var location: SourceLocation
	public var children: [any Syntax] { [value] }

	public func accept<V>(_ visitor: V, _ context: V.Context) throws -> V.Value where V : Visitor {
		try visitor.visit(self, context)
	}
	
	public let label: Token?
	public let value: any Expr
}

public protocol CallExpr: Expr {
	var callee: any Expr { get }
	var args: [CallArgument] { get }
}

public struct CallExprSyntax: CallExpr {
	public let callee: any Expr
	public let args: [CallArgument]
	public let location: SourceLocation
	public var children: [any Syntax] { [callee] + args.map(\.value) }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}
}
