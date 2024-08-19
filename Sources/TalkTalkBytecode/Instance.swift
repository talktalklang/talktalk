//
//  Instance.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/18/24.
//

public struct Instance: Hashable, Codable, Sendable {
	public var pointer: Pointer?
	public var type: Struct
	public var fields: [Value?]

	public init(pointer: Pointer? = nil, type: Struct, fields: [Value?]) {
		self.pointer = pointer
		self.type = type
		self.fields = fields
	}
}
