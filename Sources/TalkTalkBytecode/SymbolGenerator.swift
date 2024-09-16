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
	private(set) var protocols: OrderedDictionary<Symbol, SymbolInfo> = [:]

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
		case let .protocol(name):
			self.protocol(name, source: .external(moduleName))
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

	private func make(_ kind: Symbol.Kind, source: SymbolInfo.Source, group: ReferenceWritableKeyPath<SymbolGenerator, OrderedDictionary<Symbol, SymbolInfo>>) -> Symbol {
		if let parent {
			return parent.make(kind, source: source, group: group)
		}

		let symbol = if case let .external(moduleName) = source {
			Symbol(module: moduleName, kind: kind)
		} else {
			Symbol(module: moduleName, kind: kind)
		}

		if let info = self[keyPath: group][symbol] {
			return info.symbol
		}

		let symbolInfo = SymbolInfo(
			symbol: symbol,
			slot: self[keyPath: group].count,
			source: source,
			isBuiltin: false
		)

		symbols[symbol] = symbolInfo
		self[keyPath: group][symbol] = symbolInfo

		// Need to import the struct's methods too

		return symbol
	}

	public func `protocol`(_ name: String, source: SymbolInfo.Source) -> Symbol {
		make(.protocol(name), source: source, group: \.protocols)
	}

	public func generic(_ name: String, source: SymbolInfo.Source) -> Symbol {
		make(.genericType(name), source: source, group: \.generics)
	}

	public func `enum`(_ name: String, source: SymbolInfo.Source) -> Symbol {
		make(.enum(name), source: source, group: \.enums)
	}

	public func `struct`(_ name: String, source: SymbolInfo.Source) -> Symbol {
		make(.struct(name), source: source, group: \.enums)
	}

	public func value(_ name: String, source: SymbolInfo.Source) -> Symbol {
		make(.value(name), source: source, group: \.values)
	}

	public func function(_ name: String, parameters: [String], source: SymbolInfo.Source) -> Symbol {
		let symbol = make(.function(name, parameters), source: source, group: \.functions)

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
		make(.method(type, name, parameters), source: source, group: \.functions)
	}

	public func property(_ type: String, _ name: String, source: SymbolInfo.Source) -> Symbol {
		make(.property(type, name), source: source, group: \.properties)
	}
}
