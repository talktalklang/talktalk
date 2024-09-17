//
//  EnumType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/5/24.
//

import Foundation
import OrderedCollections
import TalkTalkSyntax

public class EnumType: Equatable, Hashable, CustomStringConvertible, Instantiatable {
	public func member(named name: String, in context: InferenceContext) -> InferenceResult? {
		typeContext.member(named: name)
	}

	public static func == (lhs: EnumType, rhs: EnumType) -> Bool {
		lhs.name == rhs.name && lhs.cases == rhs.cases
	}

	public var name: String
	public var cases: [EnumCase]
	var typeBindings: [TypeVariable: InferenceType] = [:]
	let typeContext: TypeContext

	init(name: String, cases: [EnumCase] = [], typeContext: TypeContext) {
		self.name = name
		self.cases = cases
		self.typeContext = typeContext
	}

	public static func extract(from type: InferenceResult) -> EnumType? {
		if case let .type(.enumType(enumType)) = type {
			return enumType
		}

		return nil
	}

	public var description: String {
		"\(name)"
	}

	public var methods: OrderedDictionary<String, InferenceResult> {
		typeContext.methods
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(cases)
	}
}
