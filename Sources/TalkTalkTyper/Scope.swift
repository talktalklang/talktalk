//
//  Scope.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct Environment {
	var captures: [String: any SemanticNode] = [:]
	public init() {}
}

public class Binding: Equatable {
	public static func == (lhs: Binding, rhs: Binding) -> Bool {
		lhs.name == rhs.name && lhs.node.is(rhs.node) && lhs.traits == rhs.traits
	}

	public enum Trait {
		case initialized, constant, escapes
	}

	public var name: String
	public var node: any SemanticNode
	public var traits: Set<Trait> = []
	public var inferedTypeFrom: (any SemanticNode)?
	public var isStub = false

	init(name: String, node: any SemanticNode, traits: Set<Trait> = []) {
		self.name = name
		self.node = node
		self.traits = traits
	}

	public var type: any SemanticType {
		get {
			inferedTypeFrom?.type ?? node.type
		}

		set {
			inferedTypeFrom?.type = newValue
		}
	}

	public var isInitialized: Bool {
		traits.contains(.initialized)
	}

	public var isConstant: Bool {
		traits.contains(.constant)
	}

	public var isEscaping: Bool {
		traits.contains(.escapes)
	}
}

public class Scope {
	public var errors: [SemanticError] = []
	public var depth: Int = 0
	public var parent: Scope?
	public var children: [Scope] = []
	public var locals: [String: Binding] = [:]
	public var environment: Environment = .init()
	public var returnNodes: [any Expression] = []

	// If a binding has an expectedReturn, we can maybe use it
	// instead of Unknown
	public var expectedReturnVia: (any SemanticNode)? {
		willSet {
			assert(newValue?.type.isKnown == true, "Should not set expected return to unknown")
		}
	}

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
			let syntax = $0.node.syntax
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

	public func inferType(
		for node: inout any SemanticNode,
		from inferedType: any SemanticNode
	) {
		node.type = inferedType.type

		for local in locals.values {
			if local.node.is(node) {
				local.inferedTypeFrom = inferedType
				local.node.type = inferedType.type
			}
		}
	}

	public func lookup(identifier: String) -> Binding? {
		locals[identifier] ?? parent?.lookup(identifier: identifier)
	}

	public func captures() -> [String: Binding] {
		var result: [String: Binding] = [:]

		guard let parent else {
			return result
		}

		for (name, binding) in parent.locals {
			if binding.isEscaping {
				result[name] = binding
			}
		}

		return result
	}

	public func binding(for node: any SemanticNode) -> Binding? {
		for local in locals.values {
			if let node = node as? VarExpression {
				return lookup(identifier: node.name)
			}

			if local.node.is(node) {
				return local
			}
		}

		return parent?.binding(for: node)
	}

	@discardableResult public func bind(
		name: String,
		to node: any SemanticNode,
		traits: Set<Binding.Trait>
	) -> Binding {
		let binding = Binding(name: name, node: node, traits: traits)
		locals[name] = binding
		return binding
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
