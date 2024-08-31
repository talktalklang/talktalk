//
//  SymbolGenerator.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/21/24.
//
import Foundation

public class SymbolGenerator {
	public let moduleName: String
	let namespace: [String]

	private var parent: SymbolGenerator?

	private(set) var functions: [Symbol: SymbolInfo] = [:]
	private(set) var values: [Symbol: SymbolInfo] = [:]
	private(set) var structs: [Symbol: SymbolInfo] = [:]
	private(set) var properties: [Symbol: SymbolInfo] = [:]
	private(set) var generics: [Symbol: SymbolInfo] = [:]

	public var symbols: [Symbol: SymbolInfo] = [:]

	public init(moduleName: String, namespace: [String] = [], parent: SymbolGenerator?) {
		self.moduleName = moduleName
		self.namespace = namespace
		self.parent = parent
	}

	public subscript(_ symbol: Symbol) -> SymbolInfo? {
		symbols[symbol]
	}

	public func new(namespace: String) -> SymbolGenerator {
		SymbolGenerator(moduleName: moduleName, namespace: self.namespace + [namespace], parent: self)
	}

	public func reserve(_ symbol: Symbol, info: SymbolInfo) {
		let info = SymbolInfo(symbol: symbol, slot: info.slot, source: .stdlib, isBuiltin: false)

		symbols[symbol] = info

		switch symbol.kind {
		case .function(_, _):
			functions[symbol] = info
		case .value(_):
			values[symbol] = info
		case .struct(_):
			structs[symbol] = info
		case .method(_, _, _):
			functions[symbol] = info
		case .genericType(_):
			generics[symbol] = info
		case .property(_, _), .primitive(_):
			()
		}
	}

	public func `import`(_ symbol: Symbol, from moduleName: String) -> Symbol {
		switch symbol.kind {
		case .primitive(_):
			return symbol
		case .function(let name, let params):
			return function(name, parameters: params, source: .external(moduleName), id: symbol.id)
		case .value(let string):
			return value(string, source: .external(moduleName), id: symbol.id)
		case .struct(let name):
			return self.struct(name, source: .external(moduleName), id: symbol.id)
		case .method(let type, let name, let params):
			return method(type, name, parameters: params, source: .external(moduleName), id: symbol.id)
		case .property(let type, let name):
			return property(type, name, source: .external(moduleName), id: symbol.id)
		case .genericType(let name):
			return generic(name, source: .external(moduleName), id: symbol.id)
		}
	}

	public func generic(_ name: String, source: SymbolInfo.Source, id: Int) -> Symbol {
		if let parent {
			return parent.generic(name, source: source, id: id)
		}

		let symbol = if case .external(let moduleName) = source {
			Symbol(module: moduleName, kind: .genericType(name), id: id)
		} else {
			Symbol(module: moduleName, kind: .genericType(name), id: id)
		}

		if let info = generics[symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: generics.count,
			source: source,
			isBuiltin: false
		)

		symbols[symbol] = symbolInfo
		generics[symbol] = symbolInfo

		// Need to import the struct's methods too


		return symbol
	}

	public func `struct`(_ name: String, source: SymbolInfo.Source, id: Int) -> Symbol {
		if let parent {
			return parent.struct(name, source: source, id: id)
		}

		// Structs are top level (for now...) so they should not be namespaced
		let symbol = if case .external(let moduleName) = source {
			Symbol(module: moduleName, kind: .struct(name), id: id)
		} else {
			Symbol(module: moduleName, kind: .struct(name), id: id)
		}

		if let info = structs[symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: structs.count,
			source: source,
			isBuiltin: false
		)

		structs[symbol] = symbolInfo
		symbols[symbol] = symbolInfo

		return symbol
	}

	public func value(_ name: String, source: SymbolInfo.Source, id: Int) -> Symbol {
		if let parent {
			return parent.value(name, source: source, id: id)
		}

		let symbol = if case .external(let moduleName) = source {
			Symbol(module: moduleName, kind: .value(name), id: id)
		} else {
			Symbol(module: moduleName, kind: .value(name), id: id)
		}

		if let info = values[symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: values.count,
			source: source,
			isBuiltin: false
		)

		values[symbol] = symbolInfo
		symbols[symbol] = symbolInfo

		return symbol
	}

	public func function(_ name: String, parameters: [String], source: SymbolInfo.Source, id: Int) -> Symbol {
		if let parent {
			return parent.function(name, parameters: parameters, source: source, id: id)
		}

		let symbol = if case .external(let moduleName) = source {
			Symbol(module: moduleName, kind: .function(name, parameters), id: id)
		} else {
			Symbol(module: moduleName, kind: .function(name, parameters), id: id)
		}

		if let info = functions[symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: functions.count,
			source: source,
			isBuiltin: [
				"print",
				"_allocate",
				"_free",
				"_deref",
				"_storePtr",
			].contains(name)
		)

		functions[symbol] = symbolInfo
		symbols[symbol] = symbolInfo

		return symbol
	}

	public func method(_ type: String, _ name: String, parameters: [String], source: SymbolInfo.Source, id: Int) -> Symbol {
		if let parent {
			return parent.method(type, name, parameters: parameters, source: source, id: id)
		}

		// Methods don't have a namespace since they're already namespaced to their type
		let symbol = if case .external(let moduleName) = source {
			Symbol(module: moduleName, kind: .method(type, name, parameters), id: id)
		} else {
			Symbol(module: moduleName, kind: .method(type, name, parameters), id: id)
		}

		if let info = functions[symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: functions.count,
			source: source,
			isBuiltin: false
		)

		functions[symbol] = symbolInfo
		symbols[symbol] = symbolInfo

		return symbol
	}

	public func property(_ type: String, _ name: String, source: SymbolInfo.Source, id: Int) -> Symbol {
		if let parent {
			return parent.property(type, name, source: source, id: id)
		}

		let symbol = if case .external(let moduleName) = source {
			Symbol(module: moduleName, kind: .property(type, name), id: id)
		} else {
			Symbol(module: moduleName, kind: .property(type, name), id: id)
		}

		if let info = properties[symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: properties.count,
			source: source,
			isBuiltin: false
		)

		properties[symbol] = symbolInfo
		symbols[symbol] = symbolInfo

		return symbol
	}
}
