//
//  EnumCase.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/6/24.
//

public extension Instance where Kind == EnumCase {
	var attachedTypes: [InferenceType] {
		type.attachedTypes.map {
			if case let .typeVar(typeVar) = $0 {
				return substitutions[typeVar] ?? $0
			} else {
				return $0
			}
		}
	}
}

public struct EnumCase: Equatable, Hashable, CustomStringConvertible, Instantiatable {
	public var typeName: String
	public var name: String
	public let index: Int
	public var attachedTypes: [InferenceType]

	init(typeName: String, name: String, index: Int, attachedTypes: [InferenceType]) {
		self.typeName = typeName
		self.name = name
		self.index = index
		self.attachedTypes = attachedTypes
	}

	public func member(named name: String, in context: InferenceContext) -> InferenceResult? {
		nil
	}

	func instantiate(in context: InferenceContext) -> Instance<EnumCase> {
		return Instance<EnumCase>(id: context.nextIdentifier(named: name), type: self, substitutions: attachedTypes.reduce(into: [:]) { res, type in
			if case let .typeVar(typeVar) = type {
				res[typeVar] = .typeVar(context.freshTypeVariable(type.description))
			}
		})
	}

	public static func extract(from type: InferenceResult) -> EnumCase? {
		if case let .type(.enumCase(enumCase)) = type {
			return enumCase
		}

		return nil
	}

	public var description: String {
		if attachedTypes.isEmpty {
			"\(name)[\(index)]"
		} else {
			"\(name)(\(attachedTypes.map(\.description).joined(separator: ", ")))[\(index)]"
		}
	}
}
