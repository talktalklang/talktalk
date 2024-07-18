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
	var typedefs: [Int: TypedValue] = [:]

	init(ast: ProgramSyntax) {
		self.ast = ast
	}

	public func define(_ node: any Syntax, as typedValue: TypedValue) {
		typedefs[node.hashValue] = typedValue
	}

	public func typedef(at position: Int) -> TypedValue? {
		for node in ast.nodes(at: position) {
			if let typedef = typedefs[node.hashValue] {
				return typedef
			}
		}

		return nil
	}
}
