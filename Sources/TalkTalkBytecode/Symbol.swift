//
//  Symbol.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkCore

public struct SymbolInfo: Equatable, Codable {
	public enum Source: Equatable, Codable {
		case `internal`, external(String)
	}

	// What symbol is this
	public let symbol: Symbol

	// What slot should this symbol go into in a chunk.
	public let slot: Int

	// Where did this come from
	public let source: Source

	public let isBuiltin: Bool

	public init(symbol: Symbol, slot: Int, source: Source, isBuiltin: Bool) {
		self.symbol = symbol
		self.slot = slot
		self.source = source
		self.isBuiltin = isBuiltin
	}
}

public struct Symbol: Hashable, Codable, CustomStringConvertible, Sendable {
	public enum Kind: Hashable, Codable, Sendable {
		case primitive(String)

		// (Function name)
		case function(String, [String])

		// (Variable name)
		case value(String)

		// (Struct name, Offset)
		case `struct`(String)

		// (Struct name, Method name, Param names, Offset)
		case method(String, String, [String])

		// (Struct name, Property name, Offset)
		case property(String, String)

		// (Type name)
		case genericType(String)
	}

	public static func primitive(_ name: String) -> Symbol {
		Symbol(module: "[builtin]", kind: .primitive(name))
	}

	public static func function(_ module: String, _ name: String, _ params: [String]) -> Symbol {
		Symbol(module: module, kind: .function(name, params))
	}

	public static func value(_ module: String, _ name: String) -> Symbol {
		Symbol(module: module, kind: .value(name))
	}

	public static func `struct`(_ module: String, _ name: String) -> Symbol {
		Symbol(module: module, kind: .struct(name))
	}

	public static func method(_ module: String, _ type: String, _ name: String, _ params: [String]) -> Symbol {
		Symbol(module: module, kind: .method(type, name, params))
	}

	public static func property(_ module: String, _ type: String, _ name: String) -> Symbol {
		Symbol(module: module, kind: .property(type, name))
	}

	public let module: String
	public let kind: Kind

	public init(module: String, kind: Kind) {
		if module == "StdLibTest",  kind == .struct("Array") {
			
		}

		self.module = module
		self.kind = kind
	}

	public var description: String {
		switch kind {
		case let .primitive(name):
			"\(name)"
		case let .function(name, params):
			"$F\(module)$\(name)$\(params.joined(separator: "_"))"
		case let .value(name):
			"$V\(module)$\(name)"
		case let .struct(name):
			"$S\(module)$\(name)"
		case let .property(type, name):
			"$P\(module)$\(type)$\(name)"
		case let .method(type, name, params):
			"$M\(module)$\(type)$\(name)$\(params.joined(separator: "_"))"
		case let .genericType(name):
			"$G\(module)$\(name)"
		}
	}
}
