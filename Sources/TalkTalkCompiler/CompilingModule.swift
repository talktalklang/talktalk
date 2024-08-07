//
//  CompilingModule.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkBytecode
import TalkTalkAnalysis

// The compiling module is used during compilation. It can then become a real Module once
// we've sorted out all the intermediary stuff
public class CompilingModule {
	let name: String

	// The completed analysis module. We use this to make sure globals are actually there when
	// asked for in globalOffset
	let analysisModule: AnalysisModule

	// The list of compiled chunks we have.
	var compiledChunks: [Int: Chunk] = [:]

	// Stores globals with their offsets. This is useful for allowing us to calculate an offset
	// for a global before it's been resolved.
	var globalOffsets: [String: Int] = [:]

	public init(name: String, analysisModule: AnalysisModule) {
		self.name = name
		self.analysisModule = analysisModule
		self.globalOffsets[name] = 0
	}

	public func finalize() -> Module {
		var module = Module(name: name)

		// Go through the list of compiled chunks, sort by offset, add to the real module
		for (_, chunk) in compiledChunks.sorted(by: { $0.key < $1.key }) {
			module.add(chunk: chunk)
		}

		return module
	}

	public func register(file: AnalyzedSourceFile) {
		globalOffsets[file.path] = globalOffsets.count
	}

	public func compile(file: AnalyzedSourceFile) throws {
		var compiler = SourceFileCompiler(name: file.path, analyzedSyntax: file.syntax)
		let chunk = try compiler.compile(in: self)

		let offset = globalOffset(for: chunk.name) ?? 0
		compiledChunks[offset] = chunk
	}

	// Get an offset for a global by name. If we already have it (it's been compiled) then just
	// return what we have. Otherwise, figure out what the offset will be and return that.
	//
	// If the analysis says that we don't have a global by this name, return nil.
	public func globalOffset(for name: String) -> Int? {
		if let offset = globalOffsets[name] {
			return offset
		}

		if analysisModule.globals[name] == nil {
			return nil
		}

		let offset = globalOffsets.count
		globalOffsets[name] = offset

		return offset
	}
}
