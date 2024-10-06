//
//  Primitive.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

public enum Primitive: Equatable, CustomStringConvertible, Hashable, Sendable {
	case int, string, bool, pointer, none

	public var description: String {
		switch self {
		case .int:
			"int"
		case .string:
			"string"
		case .bool:
			"bool"
		case .pointer:
			"pointer"
		case .none:
			"none"
		}
	}
}
