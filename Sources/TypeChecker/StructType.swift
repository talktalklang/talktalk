//
//  StructType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//
import Foundation
import OrderedCollections
import TalkTalkSyntax

public struct StructType: Equatable, Hashable, CustomStringConvertible, Instantiatable {
	public static func == (lhs: StructType, rhs: StructType) -> Bool {
		lhs.name == rhs.name && lhs.typeContext.properties == rhs.typeContext.properties
	}

	public let name: String
	public private(set) var context: InferenceContext
	var typeBindings: [TypeVariable: InferenceType] = [:]
	let typeContext: TypeContext
	public var conformances: [ProtocolType] { typeContext.conformances }

	public static func extractType(from result: InferenceResult?) -> StructType? {
		if case let .type(.structType(structType)) = result {
			return structType
		}

		return nil
	}

	public static func extractInstance(from result: InferenceResult?) -> StructType? {
		if case let .type(.structInstance(instance)) = result {
			return instance.type
		}

		return nil
	}

	init(name: String, parentContext: InferenceContext) {
		self.name = name

		let context = parentContext.childTypeContext(named: name)

		self.context = context

		guard let typeContext = context.typeContext else {
			// swiftlint:disable fatal_error
			fatalError("Could not get type context for context: \(context)")
			// swiftlint:enable fatal_error
		}
		self.typeContext = typeContext
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(typeContext.initializers)
		hasher.combine(typeContext.properties)
		hasher.combine(typeContext.methods.keys)
	}

	public var description: String {
		"\(name)(\(properties.reduce(into: []) { res, pair in res.append("\(pair.key): \(pair.value)") }.joined(separator: ", ")))"
	}

	func instantiate(with substitutions: [TypeVariable: InferenceType], in context: InferenceContext) -> Instance<StructType> {
		let instance = Instance(
			id: context.nextIdentifier(named: name),
			type: self,
			substitutions: typeContext.typeParameters.reduce(into: [:]) {
				if let sub = substitutions[$1] {
					$0[$1] = sub
				} else if context.substitutions[$1] != nil {
					$0[$1] = context.applySubstitutions(to: .typeVar($1))
				} else {
					$0[$1] = .typeVar(context.freshTypeVariable($1.description, file: #file, line: #line))
				}
			}
		)

		context.log("Instantiated \(instance), \(instance.substitutions)", prefix: "() ")

		return instance
	}

	public var initializers: OrderedDictionary<String, InferenceResult> {
		typeContext.initializers
	}

	public func member(named name: String, in context: InferenceContext) -> InferenceResult? {
		if let member = properties[name] ?? methods[name] ?? initializers[name] {
			return .type(context.applySubstitutions(to: member.asType(in: context)))
		}

		if let typeParam = typeContext.typeParameters.first(where: { $0.name == name }) {
			return .type(.typeVar(typeParam))
		}

		return nil
	}

//	func method(named name: String) -> InferenceResult? {
//		if let member = methods[name] {
//			return .type(context.applySubstitutions(to: member.asType(in: context)))
//		}
//
//		return nil
//	}

	public var properties: OrderedDictionary<String, InferenceResult> {
		typeContext.properties
	}

	public var methods: OrderedDictionary<String, InferenceResult> {
		typeContext.methods
	}
}
