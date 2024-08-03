//
//  StaticChunk.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public struct StaticChunk {
	public let code: [Byte]
	public let constants: [Value]

	public init(code: [Byte], constants: [Value]) {
		self.code = code
		self.constants = constants
	}
}
