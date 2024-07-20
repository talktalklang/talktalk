//
//  Binding.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public protocol Value {
	
}

public struct Environment {
	var captures: [String: any Value] = [:]
	public init() {}
}

public class Binding {
	public var errors: [SemanticError] = []
	public var depth: Int = 0
	public var parent: Binding?
	public var children: [Binding] = []
	public var locals: [String: any SemanticNode] = [:]
	public var environment: Environment = .init()

	public init(
		parent: Binding? = nil,
		children: [Binding] = [],
		locals: [String: any SemanticNode] = [:],
		environment: Environment = Environment()
	) {
		self.parent = parent
		self.children = children
		self.locals = locals
		self.environment = environment
	}

	public func nodeAt(line: Int, column: Int) -> (any SemanticNode)? {
		if let node = locals.values.first(where: {
			let syntax = ($0.syntax as! any Syntax)
			return syntax.line == line && syntax.column.contains(column)
		}) {
			return node
		}

		for child in children {
			if let node = child.nodeAt(line: line, column: column) {
				return node
			}
		}

		return nil
	}

	public func bind(name: String, to node: any SemanticNode) {
		locals[name] = node
	}

	func append(child: Binding) {
		children.append(child)
		parent?.append(child: child)
	}

	func child() -> Binding {
		let binding = Binding(parent: self)
		binding.depth = (parent?.depth ?? 0) + 1

		append(child: binding)

		return binding
	}
}
