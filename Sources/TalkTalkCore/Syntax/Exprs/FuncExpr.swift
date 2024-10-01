//
//  FuncExpr.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//

public protocol FuncExpr: Expr {
	var funcToken: Token { get }
	var params: ParamsExprSyntax { get }
	var body: BlockStmtSyntax { get }
	var typeDecl: (any TypeExpr)? { get }
	var name: Token? { get }
	var isStatic: Bool { get }
}

public extension FuncExpr {
	var autoname: String {
		name?.lexeme ?? "_fn_\(params.params.map(\.name).joined(separator: "_"))_\(id.id)"
	}
}

public struct FuncExprSyntax: FuncExpr, Decl {
	public var id: SyntaxID
	public let modifierTokens: [Token]
	public let funcToken: Token
	public let typeDecl: (any TypeExpr)?
	public let params: ParamsExprSyntax
	public let body: BlockStmtSyntax
	public let isStatic: Bool
	public let name: Token?
	public let location: SourceLocation
	public var children: [any Syntax] { [params, body] }

	public init(id: SyntaxID, modifierTokens: [Token], funcToken: Token, params: ParamsExprSyntax, typeDecl: (any TypeExpr)?, body: BlockStmtSyntax, isStatic: Bool, name: Token? = nil, location: SourceLocation) {
		self.id = id
		self.modifierTokens = modifierTokens
		self.funcToken = funcToken
		self.params = params
		self.typeDecl = typeDecl
		self.body = body
		self.isStatic = isStatic
		self.name = name // ??
		self.location = location
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: Visitor {
		try visitor.visit(self, scope)
	}

	public var semanticLocation: SourceLocation? {
		if let name {
			[name]
		} else {
			location
		}
	}
}
