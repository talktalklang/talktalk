//
//  Symbol.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

public enum Symbol: Hashable, Codable, CustomStringConvertible {
	// (Function name)
	case function(String)

	// (Variable name)
	case value(String)

	// (Struct name, Offset)
	case `struct`(String)

	// (Struct name, Method name, Param names, Offset)
	case method(String, String, [String])

	// (Struct name, Property name, Offset)
	case property(String, String)

	// (Struct name, Param names, Int)
	case initializer(String, [String])

	public var description: String {
		switch self {
		case let .function(name):
			"$F$\(name)"
		case let .value(name):
			"$V$\(name)"
		case let .struct(name):
			"$S$\(name)"
		case let .property(type, name):
			"$P$\(type)$\(name)"
		case let .method(type, name, params):
			"$M$\(type)$\(name)$\(params.joined(separator: "_"))"
		case let .initializer(type, params):
			"$I$\(type)$\(params.joined(separator: "_"))"
		}
	}
}
