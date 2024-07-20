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
	public var node: any SemanticNode
	public var inferedTypeFrom: (any SemanticNode)?

	init(node: any SemanticNode) {
		self.node = node
	}

	public var type: any SemanticType {
		inferedTypeFrom?.type ?? node.type
	}
}

public class Scope {
	public var errors: [SemanticError] = []
	public var depth: Int = 0
	public var parent: Scope?
	public var children: [Scope] = []
	public var locals: [String: Binding] = [:]
	public var environment: Environment = .init()
	
	// If a binding has an expectedReturn, we can maybe use it
	// instead of Unknown
	public var expectedReturnVia: (any SemanticNode)?

	public init(
		parent: Scope? = nil,
		children: [Scope] = [],
		locals: [String: Binding] = [:],
		environment: Environment = Environment()
	) {
		self.parent = parent
		self.children = children
		self.locals = locals
		self.environment = environment
	}

	public func nodeAt(line: Int, column: Int) -> (any SemanticNode)? {
		if let node = locals.values.first(where: {
			let syntax = ($0.node.syntax as! any Syntax)
			return syntax.line == line && syntax.column.contains(column)
		}) {
			return node.node
		}

		for child in children {
			if let node = child.nodeAt(line: line, column: column) {
				return node
			}
		}

		return nil
	}

	public func inferType(for node: inout any SemanticNode, from inferedType: any SemanticNode) {
		node.type = inferedType.type

		for local in locals.values {
			if local.node.is(node) {
				local.inferedTypeFrom = inferedType
			}
		}
	}

	public func bind(name: String, to node: any SemanticNode) {
		locals[name] = .init(node: node)
	}

	func append(child: Scope) {
		children.append(child)
		parent?.append(child: child)
	}

	func child() -> Scope {
		let binding = Scope(parent: self)
		binding.depth = (parent?.depth ?? 0) + 1

		append(child: binding)

		return binding
	}
}
