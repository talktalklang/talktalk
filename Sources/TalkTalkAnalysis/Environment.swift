//
//  Environment.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode
import TalkTalkCore
import TypeChecker

// An Environment represents the type environment for some scope
public class Environment {
	private var parent: Environment?
	private var locals: [String: Binding]
	private var types: [String: any LexicalScopeType] = [:]

	let inferenceContext: Context

	public var isModuleScope: Bool
	public var lexicalScope: LexicalScope?
	public var captures: [Capture]
	public var capturedValues: [Binding]
	public var importedModules: [AnalysisModule]
	public var importedSymbols: [Symbol: Binding] = [:]
	public var errors: [AnalysisError] = []
	public var exprStmtExitBehavior: AnalyzedExprStmt.ExitBehavior = .pop
	public var symbolGenerator: SymbolGenerator
	public var isInTypeParameters: Bool = false

	public private(set) var shouldReportErrors: Bool = true

	public init(
		inferenceContext: Context,
		isModuleScope: Bool = false,
		symbolGenerator: SymbolGenerator = .init(moduleName: "None", parent: nil),
		importedModules: [AnalysisModule] = [],
		parent: Environment? = nil
	) {
		self.inferenceContext = inferenceContext
		self.isModuleScope = isModuleScope
		self.symbolGenerator = symbolGenerator
		self.parent = parent
		self.locals = [:]
		self.captures = []
		self.capturedValues = []
		self.importedModules = importedModules

		if symbolGenerator.moduleName != "Standard", isModuleScope {
			do {
				try importStdlib()
			} catch {
				print("Could not load standard library: \(error)")
			}
		}
	}

	public static func topLevel(_ moduleName: String, inferenceContext: Context) -> Environment {
		Environment(
			inferenceContext: inferenceContext,
			isModuleScope: true,
			symbolGenerator: .init(moduleName: moduleName, parent: nil)
		)
	}

	public func type(for syntax: any Syntax, default type: InferenceType = .any) -> InferenceType {
		inferenceContext.find(syntax) ?? type
	}

	public var moduleName: String {
		symbolGenerator.moduleName
	}

	public func ignoringErrors(perform: () throws -> Void) throws {
		defer { self.shouldReportErrors = true }
		shouldReportErrors = false
		try perform()
	}

	// We want to collect all errors at the top level module, so walk up ancestors then add it there
	public func report(_ kind: AnalysisErrorKind, at location: SourceLocation) -> AnalysisError {
		let error = AnalysisError(kind: kind, location: location)

		if let parent {
			return parent.report(kind, at: location)
		}

		errors.append(error)
		return error
	}

	public func add(namespace: String?) -> Environment {
		if let namespace {
			Environment(inferenceContext: inferenceContext, symbolGenerator: symbolGenerator.new(namespace: namespace), parent: self)
		} else {
			Environment(inferenceContext: inferenceContext, symbolGenerator: symbolGenerator, parent: self)
		}
	}

	public func withExitBehavior(_ behavior: AnalyzedExprStmt.ExitBehavior) -> Environment {
		let environment = add(namespace: nil)
		environment.exprStmtExitBehavior = behavior
		return environment
	}

	func addLexicalScope(for type: some LexicalScopeType) -> Environment {
		let environment = Environment(inferenceContext: inferenceContext, symbolGenerator: symbolGenerator, parent: self)
		environment.lexicalScope = LexicalScope(type: type)
		return environment
	}

	public func importModule(_ analysisModule: AnalysisModule) {
		importedModules.append(analysisModule)
	}

	public func define(type name: String, as type: any LexicalScopeType) {
		types[name] = type
	}

	public func define(parameter: String, as expr: any AnalyzedExpr) {
		locals[parameter] = Binding(
			name: parameter,
			location: expr.location,
			type: type(for: expr),
			isParameter: true
		)
	}

	public func define(
		local: String,
		as expr: any Syntax,
		type: InferenceType? = nil,
		isMutable: Bool,
		isGlobal: Bool = false
	) {
		locals[local] = Binding(
			name: local,
			location: expr.location,
			definition: Definition(location: expr.semanticLocation ?? expr.location, type: type ?? self.type(for: expr, default: .void)),
			type: type ?? self.type(for: expr, default: .void),
			isGlobal: isGlobal,
			isMutable: isMutable
		)
	}

	public var bindings: [Binding] {
		Array(locals.values)
	}

	public func allBindings() -> [Binding] {
		var result = Array(locals.values)

//		result.append(contentsOf: inferenceContext.namedVariables.compactMap {
//			Binding(name: $0.key, location: [.synthetic(.identifier)], type: $0.value.asType(in: inferenceContext))
//		})

		result.append(contentsOf: BuiltinFunction.list.map { $0.binding(in: self) })
		return result
	}

	public func infer(_ name: String) -> Binding? {
		if let local = locals[name] {
			return local
		}

		return parent?.infer(name)
	}

	func getLexicalScope() -> LexicalScope? {
		lexicalScope ?? parent?.getLexicalScope()
	}

	public func lookup(_ name: String) -> Binding? {
		if let local = locals[name] {
			return local
		}

		if let existingCapture = captures.first(where: { $0.name == name }) {
			return existingCapture.binding
		}

		if let capture = capture(name: name) {
			captures.append(capture)
			return capture.binding
		}

		if let builtinFunction = BuiltinFunction.list.first(where: { $0.name == name }) {
			return builtinFunction.binding(in: self)
		}

		for module in lookupImportedModules() {
			var symbol: Symbol?
			var global: (any ModuleGlobal)?

			if let value = module.moduleValue(named: name) {
				symbol = value.symbol
				global = value
			} else if let enumType = module.moduleEnum(named: name) {
				symbol = enumType.symbol
				global = enumType
			} else if let function = module.moduleFunction(named: name) {
				symbol = function.symbol
				global = function
			} else if let type = module.moduleStruct(named: name) {
				symbol = type.symbol
				global = type
			}

			guard let symbol, let global else {
				continue
			}

			let binding = Binding(
				name: name,
				location: global.location,
				type: global.typeID,
				externalModule: module
			)

			importBinding(as: symbol, from: module.name, binding: binding)

			return binding
		}

		return nil
	}

	func importStdlib() throws {
		let stdlib = ModuleAnalyzer.stdlib
		for symbol in stdlib.symbols {
			_ = symbolGenerator.import(symbol.key, from: "Standard")
		}

		var moduleGlobals: [ModuleGlobal] = []
		moduleGlobals.append(contentsOf: Array(stdlib.structs.values))
		moduleGlobals.append(contentsOf: Array(stdlib.enums.values))
		moduleGlobals.append(contentsOf: Array(stdlib.protocols.values))

		for type in moduleGlobals {
			importBinding(
				as: symbolGenerator.import(type.symbol, from: "Standard"),
				from: "Standard",
				binding: .init(
					name: type.name,
					location: type.location,
					type: type.typeID,
					externalModule: stdlib
				)
			)
		}
	}

	func lookupImportedModules() -> [AnalysisModule] {
		if let parent {
			return parent.lookupImportedModules()
		}

		return importedModules
	}

	func importBinding(as symbol: Symbol, from moduleName: String, binding: Binding) {
		if moduleName == self.moduleName {
			return
		}

		if let parent {
			parent.importBinding(as: symbol, from: moduleName, binding: binding)
			return
		}

		assert(isModuleScope, "trying to import binding into non-module scope environment")

		importedSymbols[symbol] = binding
		_ = symbolGenerator.import(symbol, from: moduleName)
	}

	public func type(named name: String) throws -> (any LexicalScopeType)? {
		if let type = types[name] {
			return type
		}

		if let type = try parent?.type(named: name) {
			return type
		}

//		if let type = inferenceContext.type(named: name) {
//			// Try to make a binding on the fly
//			let binding = Binding(name: name, location: [.synthetic(.builtin)], type: type)
//		}

		for module in lookupImportedModules() {
			if let structType = module.structs[name] {
				let binding = lookup(name) ?? Binding(
					name: name,
					location: structType.location,
					type: structType.typeID,
					externalModule: module
				)

				importBinding(
					as: structType.symbol,
					from: module.name,
					binding: binding
				)

				return AnalysisStructType(
					id: structType.id,
					name: name,
					properties: structType.properties,
					methods: structType.methods,
					typeParameters: structType.typeParameters
				)
			}

			if let enumType = module.enums[name] {
				let binding = lookup(name) ?? Binding(
					name: name,
					location: enumType.location,
					type: enumType.typeID,
					externalModule: module
				)

				importBinding(
					as: enumType.symbol,
					from: module.name,
					binding: binding
				)
				return AnalysisEnum(
					name: name,
					methods: enumType.methods
				)
			}
		}

		return nil
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
