//
//  ParameterListSyntax.swift
//
//
//  Created by Pat Nakajima on 7/9/24.
//
public struct ParameterListSyntax: Syntax {
	public let position: Int
	public let length: Int
	public let parameters: [IdentifierSyntax]

	public subscript(_ index: Int) -> IdentifierSyntax {
		return parameters[index]
	}

	public var count: Int {
		parameters.count
	}

	public var isEmpty: Bool {
		parameters.isEmpty
	}

	public func accept<Visitor: ASTVisitor>(_ visitor: inout Visitor) -> Visitor.Value {
		visitor.visit(self)
	}
}
