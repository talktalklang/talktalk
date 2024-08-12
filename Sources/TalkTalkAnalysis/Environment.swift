//
//  Environment.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

// An Environment represents the type environment for some scope
public class Environment {
	private var parent: Environment?
	private var locals: [String: Binding]
	private var structTypes: [String: StructType] = [:]

	public var isModuleScope: Bool
	public var lexicalScope: LexicalScope?
	public var captures: [Capture]
	public var capturedValues: [Binding]
	public var importedModules: [AnalysisModule]
	public var importedSymbols: [Symbol: Binding] = [:]
	public var errors: [AnalysisError] = []

	public init(isModuleScope: Bool = false, importedModules: [AnalysisModule] = [], parent: Environment? = nil) {
		self.isModuleScope = isModuleScope
		self.parent = parent
		self.locals = [:]
		self.captures = []
		self.capturedValues = []
		self.importedModules = importedModules
	}

	// We want to collect all errors at the top level module, so walk up ancestors then add it there
	public func report(_ kind: AnalysisErrorKind, at location: SourceLocation) -> AnalysisError {
		let error = AnalysisError(kind: kind, location: location)

		if let parent = parent {
			return parent.report(kind, at: location)
		}

		errors.append(error)
		return error
	}

	public func importModule(_ analysisModule: AnalysisModule) {
		importedModules.append(analysisModule)
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
		case "i32", "int":
			return .int
		case "bool":
			return .bool
		default:
			if let scope = getLexicalScope()?.scope,
				 let scopeName = scope.name,
				 let typeParameter = scope.typeParameters.first(where: { $0.name == name }) {
				return .generic(.struct(scopeName), typeParameter.name)
			} else if let structType = lookupStruct(named: name) {
				return .struct(structType.name ?? "<anon struct>")
			}

			return .error("unknown type: \(name)")
		}
	}

	public func lookup(_ name: String) -> Binding? {
		if let local = locals[name] {
			return local
		}

		if let global = global(named: name) {
			return global
		}

		if let existingCapture = captures.first(where: { $0.name == name }) {
			return existingCapture.binding
		}

		if let capture = capture(name: name) {
			captures.append(capture)
			return capture.binding
		}

		if let builtinStruct = BuiltinStruct.lookup(name: name) {
			return builtinStruct.binding()
		}

		if name == "print" {
			// um..
			return Binding(
				name: "print",
				expr: AnalyzedFuncExpr(
					type: BuiltinFunction.print.type,
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
						typeAnalyzed: .none,
						expr: BlockExprSyntax(exprs: [], location: [.synthetic(.builtin)]),
						exprsAnalyzed: [],
						environment: self
					),
					returnsAnalyzed: nil,
					environment: .init()
				),
				type: BuiltinFunction.print.type
			)
		}

		if let scope = getLexicalScope() {
			if name == "Self" {
				return Binding(
					name: "Self",
					expr: AnalyzedVarExpr(
						typeAnalyzed: scope.type,
						expr: VarExprSyntax(token: .synthetic(.self), location: [.synthetic(.self)]),
						environment: self
					),
					type: scope.type
				)
			}

			if case .struct = scope.type {
				if let method = scope.scope.methods.values.first(where: { $0.name == name }) {
					return Binding(
						name: name,
						expr: method.expr,
						type: .member(scope.type)
					)
				}

				if let property = scope.scope.properties.values.first(where: { $0.name == name }) {
					return Binding(
						name: name,
						expr: property.expr,
						type: .member(scope.type)
					)
				}
			}
		}

		for module in importedModules {
			var symbol: Symbol?
			var global: (any ModuleGlobal)?

			if let value = module.moduleValue(named: name) {
				symbol = .value(name)
				global = value
			} else if let function = module.moduleFunction(named: name) {
				symbol = .function(name)
				global = function
			} else if let type = module.moduleStruct(named: name) {
				symbol = .struct(name)
				global = type
			}

			guard let symbol, let global else {
				return nil
			}

			let binding = Binding(
				name: name,
				expr: global.syntax,
				type: global.type,
				externalModule: module
			)

			importBinding(as: symbol, binding: binding)

			return binding
		}

		return nil
	}

	public func lookupStruct(named name: String) -> StructType? {
		if let type = structTypes[name] {
			return type
		}

		if let type = parent?.lookupStruct(named: name) {
			return type
		}

		if let binding = importedSymbols[.struct(name)],
		   let externalModule = binding.externalModule,
		   let moduleStruct = externalModule.structs[name]
		{
			return StructType(
				name: name,
				properties: moduleStruct.properties,
				methods: moduleStruct.methods,
				typeParameters: moduleStruct.typeParameters
			)
		}

		if let builtinStruct = BuiltinStruct.lookup(name: name) {
			return builtinStruct.structType()
		}

		return nil
	}

	public func update(local: String, as type: ValueType) {
		if let current = locals[local] {
			current.type = type
			locals[local] = current
		}
	}

	public func define(struct name: String, as type: StructType) {
		structTypes[name] = type
	}

	public func define(local: String, as expr: any AnalyzedExpr) {
		locals[local] = Binding(name: local, expr: expr, type: expr.typeAnalyzed)
	}

	public func define(parameter: String, as expr: any AnalyzedExpr) {
		locals[parameter] = Binding(name: parameter, expr: expr, type: expr.typeAnalyzed, isParameter: true)
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

	func importBinding(as symbol: Symbol, binding: Binding) {
		if let parent {
			parent.importBinding(as: symbol, binding: binding)
			return
		}

		assert(isModuleScope, "trying to import binding into non-module scope environment")

		importedSymbols[symbol] = binding
	}

	func global(named name: String) -> Binding? {
		guard let parent else {
			return nil
		}

		if parent.isModuleScope {
			return parent.lookup(name)
		}

		return parent.global(named: name)
	}

	public func getLexicalScope() -> LexicalScope? {
		if let lexicalScope {
			return lexicalScope
		}

		return parent?.getLexicalScope()
	}
}
