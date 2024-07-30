public protocol MemberExpr: Expr {
	var receiver: any Expr { get }
	var property: String { get }
}

public struct MemberExprSyntax: MemberExpr {
	public let receiver: any Expr
	public let property: String
	public var location: SourceLocation
	
	public func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: Visitor {
		visitor.visit(self, scope)
	}
}
