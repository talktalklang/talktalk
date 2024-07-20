//
//  Binding.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

public struct Environment {
	var captures: [String: any Value] = [:]
	public init() {}
}

public class Binding {
	public var parent: Binding?
	public var children: [Binding] = []
	public var locals: [String: any Value] = [:]
	public var environment: Environment = .init()

	public init(
		parent: Binding? = nil,
		children: [Binding] = [],
		locals: [String: any Value] = [:],
		environment: Environment = Environment()
	) {
		self.parent = parent
		self.children = children
		self.locals = locals
		self.environment = environment
	}

	func append(child: Binding) {
		children.append(child)
		parent?.append(child: child)
	}

	func child() -> Binding {
		let binding = Binding(parent: self)

		append(child: binding)

		return binding
	}
}
