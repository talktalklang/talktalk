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
	var symbols: [Symbol: Int] = [:]

	var fileChunks: [Chunk] = []

	let moduleEnvironment: [String: Module]

	public init(name: String, analysisModule: AnalysisModule, moduleEnvironment: [String: Module]) {
		self.name = name
		self.analysisModule = analysisModule
		self.moduleEnvironment = moduleEnvironment

		// Reserve offsets for globals
		for (i, (_, global)) in analysisModule.globals.enumerated() {
			symbols[.function(global.name)] = i
		}
	}

	public func finalize() -> Module {
		var chunks: [Chunk] = Array(repeating: Chunk(name: "_"), count: analysisModule.globals.count)

		// Go through the list of global chunks, sort by offset, add to the real module
		for (i, chunk) in compiledChunks.sorted(by: { $0.key < $1.key }) {
			chunks[i] = chunk
		}

		// Copy chunks for imported functions into our module (at some point it'd be nice to just be able to call into those
		// but we'll get there..)
		for (name, global) in analysisModule.globals where global.isImport {
			guard case let .external(analysis) = global.source else {
				fatalError("attempted to import symbol from non-external module")
			}

			guard let module = moduleEnvironment[analysis.name], let moduleOffset = module.symbols[.function(name)] else {
				fatalError("\(analysis.name) not found in module environment")
			}

			guard let offset = globalOffset(for: name) else {
				fatalError("no offset registered for imported symbol: \(name)")
			}


			chunks[offset] = module.chunks[moduleOffset]
		}

		let main = if let main = chunks.first(where: { $0.name == "main" }) {
			main
		} else {
			synthesizeMain()
		}

		var module = Module(name: name, main: main, symbols: symbols)
		module.chunks = chunks

		// Prepulate globals with moduleFunction values
		for (i, _) in module.chunks.enumerated() {
			module.globals[Byte(i)] = .moduleFunction(Byte(i))
		}

		return module
	}

	public func compile(file: AnalyzedSourceFile) throws {
		var compiler = SourceFileCompiler(name: file.path, analyzedSyntax: file.syntax)
		let chunk = try compiler.compile(in: self)

		// Go through the compiled chunk's subchunks and pull global chunks out to the top level
		let globalNames = Set(analysisModule.globals.values.map(\.name))
		let hoistedChunks = chunk.getSubchunks(named: globalNames)

		for chunk in hoistedChunks {
			guard let offset = symbols[.function(chunk.name)] else {
				fatalError("trying to hoist unknown function")
			}

			compiledChunks[offset] = chunk
		}

		fileChunks.append(chunk)
	}

	// Get an offset for a global by name. If we already have it (it's been compiled) then just
	// return what we have. Otherwise, figure out what the offset will be and return that.
	//
	// If the analysis says that we don't have a global by this name, return nil.
	public func globalOffset(for name: String) -> Int? {
		return symbols[.function(name)]
	}

	func synthesizeMain() -> Chunk {
		let main = Chunk(name: "main")

		for (i, fileChunk) in fileChunks.enumerated() {
			let offset = main.addChunk(fileChunk)
			main.emit(opcode: .callChunkID, line: UInt32(i))
			main.emit(byte: Byte(offset), line: UInt32(i))
		}

		main.emit(opcode: .return, line: UInt32(fileChunks.count))

		return main
	}
}
