//
//  EnumCase.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/6/24.
//

public struct EnumCase: Equatable, Hashable, CustomStringConvertible {
	public var typeName: String
	public var name: String
	public var attachedTypes: [InferenceType]

	public static func extract(from type: InferenceResult) -> EnumCase? {
		if case let .type(.enumCase(enumCase)) = type {
			return enumCase
		}

		return nil
	}

	public var description: String {
		if attachedTypes.isEmpty {
			"\(name)"
		} else {
			"\(name)(\(attachedTypes.map(\.description).joined(separator: ", ")))"
		}
	}
}
