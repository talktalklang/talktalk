//
//  StructType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//
import Foundation
struct StructType: Equatable, Hashable, CustomStringConvertible {
	static func ==(lhs: StructType, rhs: StructType) -> Bool {
		lhs.name == rhs.name && lhs.typeContext.properties == rhs.typeContext.properties
	}

	let name: String
	private(set) var context: InferenceContext
	let typeContext: TypeContext

	static func extractType(from result: InferenceResult?) -> StructType? {
		if case let .type(.structType(structType)) = result {
			return structType
		}

		return nil
	}

	static func extractInstance(from result: InferenceResult?) -> StructType? {
		if case let .type(.structInstance(instance)) = result {
			return instance.type
		}

		return nil
	}

	init(name: String, parentContext: InferenceContext) {
		self.name = name

		let context = parentContext.childTypeContext()

		self.context = context
		self.typeContext = context.typeContext!

		context.namedVariables["self"] = .structType(self)
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(typeContext.initializers)
		hasher.combine(typeContext.properties)
		hasher.combine(typeContext.methods)
	}

	var description: String {
		"\(name)(\(properties.reduce(into: "") { res, pair in res += "\(pair.key): \(pair.value)" }))"
	}

	func instantiate(with substitutions: [TypeVariable: InferenceType], in context: InferenceContext) -> Instance {
		let instance = Instance(
			id: context.nextIdentifier(named: name),
			type: self,
			substitutions: typeContext.typeParameters.reduce(into: [:]) {
				$0[$1] = substitutions[$1] ?? .typeVar(context.freshTypeVariable("\($1) [copy]", file: #file, line: #line))
			}
		)

		context.log("Instantiated \(instance), \(instance.substitutions)", prefix: "() ")

		return instance
	}

	var initializers: [String: InferenceResult] {
		typeContext.initializers
	}

	func member(named name: String) -> InferenceResult? {
		if let member = properties[name] ?? methods[name] {
			return .type(context.applySubstitutions(to: member.asType(in: context)))
		}

		return nil
	}

	func method(named name: String) -> InferenceResult? {
		if let member = methods[name] {
			return .type(context.applySubstitutions(to: member.asType(in: context)))
		}

		return nil
	}

	var properties: [String: InferenceResult] {
		typeContext.properties
	}

	var methods: [String: InferenceResult] {
		typeContext.methods
	}
}
