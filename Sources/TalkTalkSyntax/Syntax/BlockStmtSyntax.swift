//
//  BlockStmtSyntax.swift
//
//
//  Created by Pat Nakajima on 7/10/24.
//
public struct BlockStmtSyntax: Syntax, Stmt {
	public let position: Int
	public let length: Int
	public let decls: [any Decl]

	public var isEmpty: Bool {
		decls.isEmpty
	}

	public var description: String {
		"""
		{
			\(decls.map(\.description).joined(separator: "\n\t"))
		}
		"""
	}

	public var debugDescription: String {
		"""
		BlockStmtSyntax(position: \(position), length: \(length))
			decls:
				\(decls.map(\.debugDescription).joined(separator: "\n\t\t"))
		"""
	}
}
