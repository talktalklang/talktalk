//
//  LiteralSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct LiteralExprSyntax: Syntax, Expr {
	public enum Kind {
		case `true`, `false`, `nil`
	}

	public let start: Token
	public let end: Token
	public let kind: Kind

	public func accept<Visitor: ASTVisitor>(
		_ visitor: Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}

	public var description: String {
		switch kind {
		case .true:
			"true"
		case .false:
			"false"
		case .nil:
			"nil"
		}
	}
}

extension LiteralExprSyntax: Consumable {
	static func consuming(_ token: Token) -> LiteralExprSyntax? {
		let kind: LiteralExprSyntax.Kind? = switch token.kind {
		case .true: .true
		case .false: .false
		case .nil: .nil
		default: nil
		}

		guard let kind else {
			return nil
		}

		return LiteralExprSyntax(start: token, end: token, kind: kind)
	}
}
