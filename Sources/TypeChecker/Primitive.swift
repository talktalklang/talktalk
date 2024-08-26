//
//  Primitive.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

enum Primitive: CustomStringConvertible, Hashable {
	case int, string, bool, nope

	var description: String {
		switch self {
		case .int:
			"int"
		case .string:
			"string"
		case .bool:
			"bool"
		case .nope:
			"nope"
		}
	}
}
