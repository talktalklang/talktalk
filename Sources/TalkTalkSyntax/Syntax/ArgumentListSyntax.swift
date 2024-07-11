//
//  ArgumentListSyntax.swift
//
//
//  Created by Pat Nakajima on 7/9/24.
//
public struct ArgumentListSyntax: Syntax {
	public let position: Int
	public let length: Int
	public let arguments: [any Expr]

	public subscript(_ index: Int) -> any Expr {
		return arguments[index]
	}

	public var count: Int {
		arguments.count
	}

	public var isEmpty: Bool {
		arguments.isEmpty
	}

	public var description: String {
		arguments.map(\.description).joined(separator: ", ")
	}

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
