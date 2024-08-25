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
	public var exprStmtExitBehavior: AnalyzedExprStmt.ExitBehavior = .pop
	public var symbolGenerator: SymbolGenerator
	public var isInTypeParameters: Bool = false

	public private(set) var shouldReportErrors: Bool = true

	public init(
		isModuleScope: Bool = false,
		symbolGenerator: SymbolGenerator = .init(moduleName: "None", parent: nil),
		importedModules: [AnalysisModule] = [],
		parent: Environment? = nil
	) {
		self.isModuleScope = isModuleScope
		self.symbolGenerator = symbolGenerator
		self.parent = parent
		self.locals = [:]
		self.captures = []
		self.capturedValues = []
		self.importedModules = importedModules
	}

	public static func topLevel(_ moduleName: String) -> Environment {
		Environment(isModuleScope: true, symbolGenerator: .init(moduleName: moduleName, parent: nil))
	}

	func importStdlib() {
		_ = symbolGenerator.import(.struct("Standard", "Array"), from: "Standard")
		_ = symbolGenerator.import(.struct("Standard", "Dictionary"), from: "Standard")
		_ = symbolGenerator.import(.struct("Standard", "String"), from: "Standard")
		_ = symbolGenerator.import(.struct("Standard", "Int"), from: "Standard")

		if let stdlib = importedModules.first(where: { $0.name == "Standard" }) {
			importBinding(
				as: symbolGenerator.import(.struct("Standard", "Array"), from: "Standard"),
				from: "Standard",
				binding: .init(
					name: "Array",
					expr: IdentifierExprSyntax(name: "_SyntheticArrayExpr", location: [.synthetic(.identifier)]),
					type: TypeID(.instance(.struct("Array", ["Element": TypeID(.placeholder)]))),
					externalModule: stdlib
				)
			)

			importBinding(
				as: symbolGenerator.import(.struct("Standard", "String"), from: "Standard"),
				from: "Standard",
				binding: .init(
					name: "String",
					expr: IdentifierExprSyntax(name: "_SyntheticStringExpr", location: [.synthetic(.identifier)]),
					type: TypeID(.instance(.struct("String", [:]))),
					externalModule: stdlib
				)
			)

			importBinding(
				as: symbolGenerator.import(.struct("Standard", "Int"), from: "Standard"),
				from: "Standard",
				binding: .init(
					name: "Int",
					expr: IdentifierExprSyntax(name: "_SyntheticIntExpr", location: [.synthetic(.identifier)]),
					type: TypeID(.instance(.struct("Int", [:]))),
					externalModule: stdlib
				)
			)

			importBinding(
				as: symbolGenerator.import(.struct("Standard", "Dictionary"), from: "Standard"),
				from: "Standard",
				binding: .init(
					name: "Dictionary",
					expr: IdentifierExprSyntax(name: "_SyntheticDictionaryExpr", location: [.synthetic(.identifier)]),
					type: TypeID(.instance(.struct("Dictionary", ["Key": TypeID(.placeholder), "Value": TypeID(.placeholder)]))),
					externalModule: stdlib
				)
			)
		}
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

	public func withExitBehavior(_ behavior: AnalyzedExprStmt.ExitBehavior) -> Environment {
		let environment = add(namespace: nil)
		environment.exprStmtExitBehavior = behavior
		return environment
	}

	public func importModule(_ analysisModule: AnalysisModule) {
		importedModules.append(analysisModule)
	}

	public var bindings: [Binding] {
		Array(locals.values)
	}

	public func allBindings() -> [Binding] {
		var result = Array(locals.values)
		var parent = parent
		while let nextParent = parent {
			result.append(contentsOf: nextParent.allBindings())
			parent = nextParent
		}

		result.append(contentsOf: BuiltinFunction.list.map { $0.binding(in: self) })
		return result
	}

	public func infer(_ name: String) -> Binding? {
		if let local = locals[name] {
			return local
		}

		return parent?.infer(name)
	}

	public func type(named name: String?, asInstance: Bool = false) -> ValueType? {
		guard let name else {
			return .placeholder
		}

		switch name {
		case "i32", "int":
			return .int
		case "pointer":
			return .pointer
		case "bool":
			return .bool
		case "byte":
			return .byte
		default:
			if let scope = getLexicalScope()?.scope,
			   let scopeName = scope.name,
			   let typeParameter = scope.typeParameters.first(where: { $0.name == name })
			{
				if asInstance {
					return .instance(InstanceValueType(
						ofType: .generic(.struct(scopeName), typeParameter.name),
						boundGenericTypes: [:]
					))
				} else {
					return .generic(.struct(scopeName), typeParameter.name)
				}

			} else if let structType = lookupStruct(named: name) {
				if asInstance {
					return .instance(.struct(structType.name ?? "<anon struct>", structType.placeholderGenericTypes()))
				} else {
					return .struct(structType.name ?? "<anon struct>")
				}
			}

			return nil
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
			return builtinStruct.binding(in: self)
		}

		if let builtinFunction = BuiltinFunction.list.first(where: { $0.name == name }) {
			return builtinFunction.binding(in: self)
		}

		if let scope = getLexicalScope() {
			if name == "Self" {
				return Binding(
					name: "Self",
					expr: AnalyzedVarExpr(
						typeID: TypeID(scope.type),
						expr: VarExprSyntax(
							token: .synthetic(.self),
							location: [.synthetic(.self)]
						),
						symbol: symbolGenerator.value("Self", source: .internal),
						environment: self,
						analysisErrors: [],
						isMutable: false
					),
					type: TypeID(scope.type),
					isMutable: false
				)
			}

			if case .struct = scope.type {
				if let method = scope.scope.methods.values.first(where: { $0.name == name }) {
					return Binding(
						name: name,
						expr: method.expr,
						type: TypeID(.member(.instance(InstanceValueType(ofType: scope.type, boundGenericTypes: [:]))))
					)
				}

				if let property = scope.scope.properties.values.first(where: { $0.name == name }) {
					return Binding(
						name: name,
						expr: property.expr,
						type: TypeID(.member(.instance(InstanceValueType(ofType: scope.type, boundGenericTypes: [:]))))
					)
				}
			}
		}

		for module in importedModules {
			var symbol: Symbol?
			var global: (any ModuleGlobal)?

			if let value = module.moduleValue(named: name) {
				symbol = value.symbol
				global = value
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
				expr: global.syntax,
				type: global.typeID,
				externalModule: module
			)

			importBinding(as: symbol, from: module.name, binding: binding)

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

		// See if we already know about this somewhere else, if so, use it.
//		if let binding = importedSymbols.first(where: { $0.key.kind == .struct(name) })?.value,
//		   let externalModule = binding.externalModule,
//		   let moduleStruct = externalModule.structs[name]
//		{
//			importBinding(as: moduleStruct.symbol, from: externalModule.name, binding: binding)
//
//			return StructType(
//				name: name,
//				properties: moduleStruct.properties,
//				methods: moduleStruct.methods,
//				typeParameters: moduleStruct.typeParameters
//			)
//		}

		if let builtinStruct = BuiltinStruct.lookup(name: name) {
			return builtinStruct.structType()
		}

		// See if any of our imported modoules have this struct
		for module in importedModules {
			if let moduleStruct = module.moduleStruct(named: name) {
				importBinding(
					as: moduleStruct.symbol,
					from: module.name,
					binding: Binding(
						name: name,
						expr: moduleStruct.syntax,
						type: moduleStruct.typeID,
						externalModule: module
					)
				)

				return StructType(
					name: name,
					properties: moduleStruct.properties,
					methods: moduleStruct.methods,
					typeParameters: moduleStruct.typeParameters
				)
			}
		}

		return nil
	}

	public func update(local: String, as type: ValueType) {
		if let current = locals[local] {
			current.type.update(type, location: current.expr.location)
			locals[local] = current
		}

		parent?.update(local: local, as: type)
	}

	public func define(struct name: String, as type: StructType) {
		structTypes[name] = type
	}

	public func local(named: String) -> Binding? {
		locals[named]
	}

	public func define(
		local: String,
		as expr: any AnalyzedExpr,
		definition: (any AnalyzedExpr)? = nil,
		isMutable: Bool,
		isGlobal: Bool = false
	) {
		locals[local] = Binding(
			name: local,
			expr: expr,
			definition: definition,
			type: expr.typeID,
			isGlobal: isGlobal,
			isMutable: isMutable
		)
	}

	public func define(parameter: String, as expr: any AnalyzedExpr) {
		locals[parameter] = Binding(
			name: parameter,
			expr: expr,
			type: expr.typeID,
			isParameter: true
		)
	}

	public func addLexicalScope(scope: StructType, type: ValueType, expr: any Syntax) -> Environment {
		let environment = Environment(symbolGenerator: symbolGenerator.new(namespace: scope.name ?? "\(scope)"), parent: self)
		environment.lexicalScope = LexicalScope(scope: scope, type: type, expr: expr)
		return environment
	}

	public func add(namespace: String?) -> Environment {
		if let namespace {
			Environment(symbolGenerator: symbolGenerator.new(namespace: namespace), parent: self)
		} else {
			Environment(symbolGenerator: symbolGenerator, parent: self)
		}
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
