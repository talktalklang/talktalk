//
//  SymbolGenerator.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/21/24.
//

public class SymbolGenerator {
	let moduleName: String
	let namespace: [String]

	var parent: SymbolGenerator?

	var functions: [Symbol: SymbolInfo] = [:]
	var values: [Symbol: SymbolInfo] = [:]
	var structs: [Symbol: SymbolInfo] = [:]
	var properties: [Symbol: SymbolInfo] = [:]
	public var symbols: [Symbol] = []

	public init(moduleName: String, namespace: [String] = [], parent: SymbolGenerator?) {
		self.moduleName = moduleName
		self.namespace = namespace
		self.parent = parent
	}

	public subscript(_ symbol: Symbol) -> SymbolInfo? {
		functions[symbol] ?? values[symbol] ?? structs[symbol] ?? properties[symbol]
	}

	public func new(namespace: String) -> SymbolGenerator {
		SymbolGenerator(moduleName: moduleName, namespace: self.namespace + [namespace], parent: self)
	}

	public func `import`(_ symbol: Symbol, from moduleName: String) -> Symbol {
		switch symbol.kind {
		case .primitive(let string):
			return symbol
		case .function(let name, let params):
			return function(name, parameters: params, source: .external(moduleName))
		case .value(let string):
			return value(string, source: .external(moduleName))
		case .struct(let name):
			return self.struct(name, source: .external(moduleName))
		case .method(let type, let name, let params):
			return method(type, name, parameters: params, source: .external(moduleName))
		case .property(let type, let name):
			return property(type, name, source: .external(moduleName))
		}
	}

	public func `struct`(_ name: String, source: SymbolInfo.Source, namespace: [String]? = nil) -> Symbol {
		if let parent {
			return parent.struct(name, source: source, namespace: namespace ?? self.namespace)
		}

		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: .struct(name), namespace: namespace ?? self.namespace)
		} else {
			Symbol(module: moduleName, kind: .struct(name), namespace: namespace ?? self.namespace)
		}

		if let info = structs[symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: structs.count,
			source: source
		)

		structs[symbol] = symbolInfo

		symbols.append(symbol)
		return symbol
	}

	public func value(_ name: String, source: SymbolInfo.Source, namespace: [String]? = nil) -> Symbol {
		if let parent {
			return parent.value(name, source: source, namespace: namespace ?? self.namespace)
		}

		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: .value(name), namespace: namespace ?? self.namespace)
		} else {
			Symbol(module: moduleName, kind: .value(name), namespace: namespace ?? self.namespace)
		}

		if let info = values[symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: values.count,
			source: source
		)

		values[symbol] = symbolInfo

		symbols.append(symbol)
		return symbol
	}

	public func function(_ name: String, parameters: [String], source: SymbolInfo.Source, namespace: [String]? = nil) -> Symbol {
		if let parent {
			return parent.function(name, parameters: parameters, source: source, namespace: namespace ?? self.namespace)
		}

		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: .function(name, parameters), namespace: namespace ?? self.namespace)
		} else {
			Symbol(module: moduleName, kind: .function(name, parameters), namespace: namespace ?? self.namespace)
		}

		if let info = functions[symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: functions.count,
			source: source
		)

		functions[symbol] = symbolInfo

		symbols.append(symbol)
		return symbol
	}

	public func method(_ type: String, _ name: String, parameters: [String], source: SymbolInfo.Source, namespace: [String]? = nil) -> Symbol {
		if let parent {
			return parent.method(type, name, parameters: parameters, source: source, namespace: namespace ?? self.namespace)
		}

		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: .method(type, name, parameters), namespace: namespace ?? self.namespace)
		} else {
			Symbol(module: moduleName, kind: .method(type, name, parameters), namespace: namespace ?? self.namespace)
		}

		if let info = functions[symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: functions.count,
			source: source
		)

		functions[symbol] = symbolInfo

		symbols.append(symbol)
		return symbol
	}

	public func property(_ type: String, _ name: String, source: SymbolInfo.Source, namespace: [String]? = nil) -> Symbol {
		if let parent {
			return parent.property(type, name, source: source, namespace: namespace ?? self.namespace)
		}

		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: .property(type, name), namespace: namespace ?? self.namespace)
		} else {
			Symbol(module: moduleName, kind: .property(type, name), namespace: namespace ?? self.namespace)
		}

		if let info = properties[symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: properties.count,
			source: source
		)

		properties[symbol] = symbolInfo

		symbols.append(symbol)
		return symbol
	}
}
