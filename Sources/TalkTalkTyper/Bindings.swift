//
//  Results.swift
//  
//
//  Created by Pat Nakajima on 7/15/24.
//
import TalkTalkSyntax

public class Bindings {
	public var ast: ProgramSyntax
	public var errors: [TypeError] = []
	public var warnings: [String] = []
	private var typedefs: [Int: TypedValue] = [:]

	init(ast: ProgramSyntax) {
		self.ast = ast
	}

	public func define(_ node: any Syntax, as typedValue: TypedValue) {
		self.typedefs[node.hashValue] = typedValue
	}

	public func typedef(at position: Int) -> TypedValue? {
		let node = ast.node(at: position)
		return typedefs[node.hashValue]
	}
}
