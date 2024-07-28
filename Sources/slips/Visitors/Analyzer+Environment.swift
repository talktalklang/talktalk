//
//  Analyzer+Environment.swift
//  Slips
//
//  Created by Pat Nakajima on 7/27/24.
//

public extension Analyzer {
	class Environment {
		public struct Capture {
			public let name: String
			public let binding: Binding
			public let environment: Environment
		}

		public class Binding {
			public let name: String
			public var expr: any AnalyzedExpr
			public var type: ValueType { didSet { self.expr.type = type } }
			public var isCaptured: Bool

			public init(name: String, expr: any AnalyzedExpr, isCaptured: Bool = false) {
				self.name = name
				self.expr = expr
				self.type = expr.type
				self.isCaptured = isCaptured
			}
		}

		private var parent: Environment?
		private var locals: [String: Binding]
		public var captures: [Capture]
		public var capturedValues: [Binding]

		public init(parent: Environment? = nil) {
			self.parent = parent
			self.locals = [:]
			self.captures = []
			self.capturedValues = []
		}

		public var bindings: [Binding] {
			Array(locals.values)
		}

		public func infer(_ name: String) -> Binding? {
			if let local = locals[name] {
				return local
			}

			return parent?.infer(name)
		}

		public func lookup(_ name: String) -> Binding? {
			if let local = locals[name] {
				return local
			}

			if let capture = capture(name: name) {
				captures.append(capture)
				return capture.binding
			}

			return nil
		}

		public func update(local: String, as type: ValueType) {
			if let current = locals[local] {
				current.type = type
				locals[local] = current
			}
		}

		public func define(local: String, as expr: any AnalyzedExpr) {
			locals[local] = Binding(name: local, expr: expr)
		}

		public func add() -> Environment {
			Environment(parent: self)
		}

		func capture(name: String) -> Capture? {
			if let local = locals[name] {
				local.isCaptured = true
				capturedValues.append(local)
				return Capture(name: name, binding: local, environment: self)
			}

			if let parent {
				return parent.capture(name: name)
			}

			return nil
		}
	}
}
