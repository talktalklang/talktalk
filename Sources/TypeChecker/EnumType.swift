//
//  EnumType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/5/24.
//

import Foundation
import TalkTalkSyntax
import OrderedCollections

public struct EnumType: Equatable, Hashable, CustomStringConvertible {
	public static func ==(lhs: EnumType, rhs: EnumType) -> Bool {
		lhs.name == rhs.name && lhs.cases == rhs.cases
	}

	public var name: String
	public var cases: [EnumCase]
	var typeBindings: [TypeVariable: InferenceType] = [:]
	let typeContext: TypeContext

	public static func extract(from type: InferenceResult) -> EnumType? {
		if case let .type(.enumType(enumType)) = type {
			return enumType
		}

		return nil
	}

	public var description: String {
		"\(name)"
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(cases)
	}
}
