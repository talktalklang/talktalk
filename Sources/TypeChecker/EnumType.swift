//
//  EnumType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/5/24.
//

import Foundation
import TalkTalkSyntax
import OrderedCollections

public struct EnumCase: Equatable, Hashable, CustomStringConvertible {
	public var typeName: String
	public var name: String
	public var attachedTypes: [InferenceType]

	public static func extract(from type: InferenceResult) -> EnumCase? {
		if case let .type(.enumCase(_, enumCase)) = type {
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

public struct EnumType: Equatable, Hashable, CustomStringConvertible {
	public var name: String
	public var cases: [EnumCase]

	public static func extract(from type: InferenceResult) -> EnumType? {
		if case let .type(.enumType(enumType)) = type {
			return enumType
		}

		return nil
	}

	public var description: String {
		"\(name)"
	}
}
