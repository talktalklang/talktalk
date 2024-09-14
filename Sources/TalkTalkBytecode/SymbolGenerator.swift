//
//  SymbolGenerator.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/21/24.
//
import Foundation
import OrderedCollections
import TalkTalkCore

public class SymbolGenerator {
	public let moduleName: String
	let namespace: [String]

	private var parent: SymbolGenerator?

	private(set) var functions: OrderedDictionary<Symbol, SymbolInfo> = [:]
	private(set) var values: OrderedDictionary<Symbol, SymbolInfo> = [:]
	private(set) var structs: OrderedDictionary<Symbol, SymbolInfo> = [:]
	private(set) var properties: OrderedDictionary<Symbol, SymbolInfo> = [:]
	private(set) var generics: OrderedDictionary<Symbol, SymbolInfo> = [:]
	private(set) var enums: OrderedDictionary<Symbol, SymbolInfo> = [:]

	public var symbols: OrderedDictionary<Symbol, SymbolInfo> = [:]

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

	public func `import`(_ symbol: Symbol, from moduleName: String) -> Symbol {
		switch symbol.kind {
		case .primitive:
			symbol
		case let .function(name, params):
			function(name, parameters: params, source: .external(moduleName))
		case let .value(string):
			value(string, source: .external(moduleName))
		case let .struct(name):
			self.struct(name, source: .external(moduleName))
		case let .method(type, name, params):
			method(type, name, parameters: params, source: .external(moduleName))
		case let .property(type, name):
			property(type, name, source: .external(moduleName))
		case let .enum(name):
			self.enum(name, source: .external(moduleName))
		case let .genericType(name):
			generic(name, source: .external(moduleName))
		}
	}

	public func generic(_ name: String, source: SymbolInfo.Source) -> Symbol {
		if let parent {
			return parent.generic(name, source: source)
		}

		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: .genericType(name))
		} else {
			Symbol(module: moduleName, kind: .genericType(name))
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

	public func `enum`(_ name: String, source: SymbolInfo.Source) -> Symbol {
		if let parent {
			return parent.enum(name, source: source)
		}

		// Structs are top level (for now...) so they should not be namespaced
		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: .enum(name))
		} else {
			Symbol(module: moduleName, kind: .enum(name))
		}

		if let info = enums[symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: enums.count,
			source: source,
			isBuiltin: false
		)

		enums[symbol] = symbolInfo
		symbols[symbol] = symbolInfo

		return symbol
	}

	public func `struct`(_ name: String, source: SymbolInfo.Source) -> Symbol {
		if let parent {
			return parent.struct(name, source: source)
		}

		// Structs are top level (for now...) so they should not be namespaced
		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: .struct(name))
		} else {
			Symbol(module: moduleName, kind: .struct(name))
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

	public func value(_ name: String, source: SymbolInfo.Source) -> Symbol {
		if let parent {
			return parent.value(name, source: source)
		}

		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: .value(name))
		} else {
			Symbol(module: moduleName, kind: .value(name))
		}

		if let info = values[symbol] {
			return info.symbol
		} else {}

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

	public func function(_ name: String, parameters: [String], source: SymbolInfo.Source) -> Symbol {
		if let parent {
			return parent.function(name, parameters: parameters, source: source)
		}

		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: .function(name, parameters))
		} else {
			Symbol(module: moduleName, kind: .function(name, parameters))
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

	public func method(_ type: String, _ name: String, parameters: [String], source: SymbolInfo.Source) -> Symbol {
		if let parent {
			return parent.method(type, name, parameters: parameters, source: source)
		}

		// Methods don't have a namespace since they're already namespaced to their type
		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: .method(type, name, parameters))
		} else {
			Symbol(module: moduleName, kind: .method(type, name, parameters))
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

	public func property(_ type: String, _ name: String, source: SymbolInfo.Source) -> Symbol {
		if let parent {
			return parent.property(type, name, source: source)
		}

		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: .property(type, name))
		} else {
			Symbol(module: moduleName, kind: .property(type, name))
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
