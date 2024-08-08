//
//  SerializedModule.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode

public struct SerializedModule: Codable {
	public let analysis: SerializedAnalysisModule

	// The main chunk for this module
	public var main: Chunk

	// The list of chunks in this module
	public var chunks: [Chunk]

	// A list of symbols this module exports
	public var symbols: [Symbol: Int]

	// A list of modules this module imports
	public var imports: [String] = []

	// If a global value hasn't been used yet, its initializer goes into
	// here so it can be initialized lazily
	public var valueInitializers: [Byte: Chunk]
}
