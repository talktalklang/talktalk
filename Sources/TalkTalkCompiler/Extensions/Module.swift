//
//  Module.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode

public extension Module {
	// A helper for when we just want to run a chunk
	static func main(_ chunk: Chunk) -> Module {
		Module(name: "main", main: chunk, symbols: [:])
	}
}
