//
//  Module.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import OrderedCollections

public final class BoundEnumCase: Equatable, Codable, Hashable, CustomStringConvertible , Sendable {
	public static func == (lhs: BoundEnumCase, rhs: BoundEnumCase) -> Bool {
		lhs.type == rhs.type && lhs.name == rhs.name && lhs.values == rhs.values
	}

	// The name of the enum this case belongs to.
	public let type: String

	// The name of this case. All cases have names even if they don't have
	// associated values.
	public let name: String

	// Associated values for the enum
	public let values: [Value]

	public init(type: String, name: String, values: [Value]) {
		self.type = type
		self.name = name
		self.values = values
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(type)
		hasher.combine(name)
		hasher.combine(values)
	}

	public var description: String {
		"\(type).\(name)(\(values))"
	}
}

public struct EnumCase: Equatable, Sendable, Codable, Hashable {
	public let type: String

	// The name of this case. All cases have names even if they don't have
	// associated values.
	public let name: String

	// Associated values for the enum
	public let arity: Int

	public init(type: String, name: String, arity: Int) {
		self.type = type
		self.name = name
		self.arity = arity
	}
}

public struct Enum: Equatable, Sendable, Codable, Hashable {
	// What is this enum named
	public let name: String

	// What are the cases of this enum
	public let cases: [StaticSymbol: EnumCase]

	public init(name: String, cases: [StaticSymbol: EnumCase]) {
		self.name = name
		self.cases = cases
	}
}

public struct Module: Equatable, @unchecked Sendable {
	// The name of the module. P straightforward.
	public let name: String

	// For executable modules, this is the entry chunk to be run
	public var main: StaticChunk?

	// The list of chunks in this module
	public var chunks: [StaticSymbol: StaticChunk] = [:]

	// The list of top level structs in this module
	public var structs: [StaticSymbol: Struct] = [:]

	// The list of top level enums in this module
	public var enums: [StaticSymbol: Enum] = [:]

	// A list of symbols this module exports
	public var symbols: OrderedDictionary<Symbol, SymbolInfo>

	// A list of modules this module imports
	public var imports: [Module] = []

	// If a global value hasn't been used yet, its initializer goes into
	// here so it can be initialized lazily
	public var valueInitializers: [StaticSymbol: StaticChunk] = [:]

	public init(name: String, main: StaticChunk? = nil, symbols: OrderedDictionary<Symbol, SymbolInfo>) {
		self.name = name
		self.main = main
		self.symbols = symbols
	}

	public mutating func add(chunk: StaticChunk) {
		chunks[chunk.symbol.asStatic()] = chunk
	}
}
