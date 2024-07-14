//
//  ArgumentListSyntax.swift
//
//
//  Created by Pat Nakajima on 7/9/24.
//
public struct ArgumentListSyntax: Syntax {
	public let start: Token
	public let end: Token
	public let arguments: [any Expr]

	public static func ==(lhs: Self, rhs: Self) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(start)
		hasher.combine(end)
		for argument in arguments {
			hasher.combine(argument)
		}
	}

	public subscript(_ index: Int) -> any Expr {
		return arguments[index]
	}

	public var count: Int {
		arguments.count
	}

	public var isEmpty: Bool {
		arguments.isEmpty
	}

	public func accept<Visitor: ASTVisitor>(
		_ visitor: inout Visitor,
		context: Visitor.Context
	) -> Visitor.Value {
		visitor.visit(self, context: context)
	}
}
