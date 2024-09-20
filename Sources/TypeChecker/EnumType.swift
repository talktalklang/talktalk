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
	public static func == (lhs: EnumType, rhs: EnumType) -> Bool {
		lhs.name == rhs.name && lhs.cases.map(\.name) == rhs.cases.map(\.name)
	}

	public var name: String
	public var cases: [EnumCase]
	public var conformances: [ProtocolType] { typeContext.conformances }
	public let context: InferenceContext
	public let typeContext: TypeContext

	init(name: String, cases: [EnumCase] = [], context: InferenceContext, typeContext: TypeContext) {
		self.name = name
		self.cases = cases
		self.context = context
		self.typeContext = typeContext
	}

	public static func extract(from type: InferenceResult) -> EnumType? {
		if case let .type(.instantiatable(.enumType(enumType))) = type {
			return enumType
		}

		if case let .type(.instance(instance)) = type {
			return instance.type as? EnumType
		}

		return nil
	}

	public var description: String {
		"\(name)"
	}

	public func apply(substitutions: OrderedDictionary<TypeVariable, InferenceType>, in context: InferenceContext) -> InferenceType {
		.instantiatable(.enumType(EnumType(
			name: name,
			cases: cases.map {
				// swiftlint:disable force_unwrapping
				EnumCase.extract(from: .type(context.applySubstitutions(to: .enumCase($0), with: substitutions)))!
				// swiftlint:enable force_unwrapping
			},
			context: context,
			typeContext: typeContext
		)))
	}

	public func member(named name: String, in _: InferenceContext) -> InferenceResult? {
		if let member = typeContext.member(named: name) {
			return member
		}

		if let kase = cases.first(where: { $0.name == name }) {
			return .type(.enumCase(kase))
		}

		return nil
	}

	public var methods: OrderedDictionary<String, InferenceResult> {
		typeContext.methods
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(cases.map(\.name))
	}
}
