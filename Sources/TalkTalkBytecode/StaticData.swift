//
//  StaticData.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

public struct StaticData: Codable, Hashable, Equatable, Sendable {
	public enum Kind: String, Codable, Sendable {
		case string = "String"
	}

	public let kind: Kind
	public let bytes: ContiguousArray<Byte>

	public init(kind: Kind, bytes: some Collection<Byte>) {
		self.kind = kind
		self.bytes = ContiguousArray(bytes)
	}
}
