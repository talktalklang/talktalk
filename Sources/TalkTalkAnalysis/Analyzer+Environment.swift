//
//  Analyzer+Environment.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/27/24.
//

import TalkTalkSyntax

public class LexicalScope {
	public var scope: StructType
	var type: ValueType
	var expr: any Expr

	init(scope: StructType, type: ValueType, expr: any Expr) {
		self.scope = scope
		self.type = type
		self.expr = expr
	}
}

public extension Analyzer {
	class Environment {
		public struct Capture: CustomStringConvertible {
			public static func any(_ name: String) -> Capture {
				Capture(
					name: name,
					binding: .init(
						name: name,
						expr: AnalyzedLiteralExpr(
							type: .bool,
							expr: LiteralExprSyntax(value: .bool(true), location: [.synthetic(.true)]),
							environment: .init()
						),
						type: .bool
					),
					environment: .init()
				)
			}

			public let name: String
			public let binding: Binding
			public let environment: Environment

			public var description: String {
				".capture(\(name))"
			}
		}

		public class Binding {
			public let name: String
			public var expr: any Syntax
			public var type: ValueType
			public var isCaptured: Bool
			public var isBuiltin: Bool
			public var isParameter: Bool

			public init(name: String, expr: any Syntax, type: ValueType, isCaptured: Bool = false, isBuiltin: Bool = false, isParameter: Bool = false) {
				self.name = name
				self.expr = expr
				self.type = type
				self.isCaptured = isCaptured
				self.isBuiltin = isBuiltin
				self.isParameter = isParameter
			}
		}

		private var parent: Environment?
		private var locals: [String: Binding]

		public var lexicalScope: LexicalScope?
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

		public func type(named name: String) -> ValueType {
			switch name {
			case "i32": .int
			case "bool": .bool
			default:
				fatalError()
			}
		}

		public func lookup(_ name: String) -> Binding? {
			if let local = locals[name] {
				return local
			}

			if let capture = capture(name: name) {
				captures.append(capture)
				return capture.binding
			}

			if name == "printf" {
				// um..
				return Binding(
					name: "printf",
					expr: AnalyzedFuncExpr(
						type: Builtin.print.type,
						expr: FuncExprSyntax(
							funcToken: .synthetic(.func),
							params: ParamsExprSyntax(
								params: [.int("value")],
								location: [.synthetic(.builtin)]
							),
							body: BlockExprSyntax(exprs: [], location: [.synthetic(.builtin)]),
							i: -1,
							location: [.synthetic(.builtin)]
						),
						analyzedParams: [.int("value")],
						bodyAnalyzed: AnalyzedBlockExpr(
							type: .none,
							expr: BlockExprSyntax(exprs: [], location: [.synthetic(.builtin)]),
							exprsAnalyzed: [],
							environment: self
						),
						returnsAnalyzed: nil,
						environment: .init()
					),
					type: Builtin.print.type
				)
			}

			if let scope = getLexicalScope() {
				if name == "Self" {
					return Binding(
						name: "Self",
						expr: AnalyzedVarExpr(
							type: scope.type,
							expr: VarExprSyntax(token: .synthetic(.self), location: [.synthetic(.self)]),
							environment: self
						),
						type: scope.type
					)
				}

				if case let .struct(type) = scope.type {
					if let method = type.methods[name] {
						return Binding(
							name: name,
							expr: method.expr,
							type: .instanceValue(scope.type)
						)
					}

					if let property = type.properties[name] {
						return Binding(
							name: name,
							expr: property.expr,
							type: .instanceValue(scope.type)
						)
					}
				}
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
			locals[local] = Binding(name: local, expr: expr, type: expr.type)
		}

		public func define(parameter: String, as expr: any AnalyzedExpr) {
			locals[parameter] = Binding(name: parameter, expr: expr, type: expr.type, isParameter: true)
		}

		public func addLexicalScope(scope: StructType, type: ValueType, expr: any Expr) -> Environment {
			let environment = Environment(parent: self)
			environment.lexicalScope = LexicalScope(scope: scope, type: type, expr: expr)
			return environment
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

		public func getLexicalScope() -> LexicalScope? {
			if let lexicalScope {
				return lexicalScope
			}

			return parent?.getLexicalScope()
		}
	}
}
