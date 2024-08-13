public protocol MemberExpr: Expr {
	var receiver: any Expr { get }
	var property: String { get }
	var propertyToken: Token { get }
}

public struct MemberExprSyntax: MemberExpr {
	public let receiver: any Expr
	public let property: String
	public let propertyToken: Token
	public var location: SourceLocation
	public var children: [any Syntax] { [receiver] }

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}
}
