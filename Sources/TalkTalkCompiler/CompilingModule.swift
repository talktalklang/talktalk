//
//  CompilingModule.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode

// The compiling module is used during compilation. It can then become a real Module once
// we've sorted out all the intermediary stuff
public class CompilingModule {
	let name: String

	// The completed analysis module. We use this to make sure globals are actually there when
	// asked for in globalOffset
	let analysisModule: AnalysisModule

	// The list of compiled chunks we have.
	var compiledChunks: [Chunk] = []

	// The chunks created for each file being compiled. We can use these to synthesize a main function
	// if none exists.
	var fileChunks: [Chunk] = []

	// Lazy initializers for globals
	var valueInitializers: [Symbol: Chunk] = [:]

	// Top level structs for this module
	var structs: [Symbol: Struct] = [:]
	var structMethods: [Symbol: [Symbol: Chunk]] = [:]

	// The available modules for import
	let moduleEnvironment: [String: Module]

	public init(name: String, analysisModule: AnalysisModule, moduleEnvironment: [String: Module]) {
		self.name = name
		self.analysisModule = analysisModule
		self.moduleEnvironment = moduleEnvironment
	}

	public func finalize(mode: CompilationMode) -> Module {
		let chunkCount = analysisModule.symbols.keys.count(where: { symbol in
			if case .function(_, _) = symbol.kind {
				return true
			} else if case .method(_, _, _) = symbol.kind {
				return true
			} else {
				return false
			}
		})

		var chunks: [StaticChunk] = Array(
			repeating: StaticChunk(
				chunk: .init(name: "_", symbol: .function(name, "_", [], namespace: []), path: "_")
			),
			count: chunkCount
		)
		var moduleStructs: [Struct] = Array(repeating: Struct(name: "_", propertyCount: 0), count: analysisModule.structs.count)

		for (symbol, info) in analysisModule.symbols {
			if info.isBuiltin { continue }

			switch symbol.kind {
			case .function:
				if let chunk = compiledChunks.first(where: { $0.symbol == symbol }) {
					chunks[info.slot] = StaticChunk(chunk: chunk)
					continue
				}

				// Copy the external method into our chunks, using the slot we want
				if case let .external(name) = info.source,
					 let module = moduleEnvironment[name],
					 let moduleInfo = module.symbols[symbol] {
					chunks[info.slot] = module.chunks[moduleInfo.slot]
					continue
				}

				fatalError("could not find compiled chunk for: \(symbol.description)")
			case .struct:
				switch info.source {
				case .stdlib:
					if self.name == "Standard" {
						// In this case, we're the Standard library compiling itself so we should have the
						// struct here in this CompilingModule
						guard let structType = structs[symbol] else {
							fatalError("could not find struct for: \(symbol.description)")
						}
						moduleStructs[info.slot] = structType
					} else {
						// Otherwise, we can assume it's in the module environment
						guard let module = moduleEnvironment["Standard"],
									let moduleInfo = module.symbols[symbol] else {
							fatalError("could not find struct for: \(symbol.description)")
							continue
						}

						moduleStructs[info.slot] = module.structs[moduleInfo.slot]
					}
				case .external(let name):
					guard let module = moduleEnvironment[name],
								let moduleInfo = module.symbols[symbol] else {
						print("could not find struct for: \(symbol.description)")
						continue
					}

					moduleStructs[info.slot] = module.structs[moduleInfo.slot]
				case .internal:
					guard let structType = structs[symbol] else {
						fatalError("could not find struct for: \(symbol.description)")
					}

					moduleStructs[info.slot] = structType
				}
			case .value(_), .primitive, .genericType(_), .property, .method:
				()
			}
		}

		var module = Module(name: name, main: nil, symbols: analysisModule.symbols)

		// Set the module level function chunks
		module.chunks = chunks
		module.structs = moduleStructs

		if mode == .executable {
			// If we're in executable compilation mode, we need an entry point. If we already have a func named "main" then
			// we can use that. Otherwise synthesize one out of the files in the module.
			if let existingMain = chunks.first(where: { $0.name == "main" }) {
				module.main = existingMain
			} else {
				let synthesized = synthesizeMain()
				module.chunks.append(.init(chunk: synthesized))
				module.main = StaticChunk(chunk: synthesized)
			}
		}

		// Copy lazy value initializers
		for (name, chunk) in valueInitializers {
			let symbol = analysisModule.symbols[name]!
			module.valueInitializers[Byte(symbol.slot)] = StaticChunk(chunk: chunk)
		}

		return module
	}

	public func compile(file: AnalyzedSourceFile) throws -> Chunk {
		var compiler = SourceFileCompiler(name: file.path, module: name, analyzedSyntax: file.syntax, path: file.path)
		let chunk = try compiler.compile(in: self)
		compiledChunks.append(chunk)
		fileChunks.append(chunk)
		return chunk
	}

	// Get an offset for a global by name. If we already have it (it's been compiled) then just
	// return what we have. Otherwise, figure out what the offset will be and return that.
	//
	// If the analysis says that we don't have a global by this name, return nil.
	public func moduleFunctionOffset(for string: String) -> Int? {
		for (symbol, info) in analysisModule.symbols {
			if case .function(string, _) = symbol.kind {
				return info.slot
			}
		}
		
		return nil
	}

	public func moduleValueOffset(for symbol: Symbol) -> Int? {
		if case .value = symbol.kind {
			return analysisModule.symbols[symbol]?.slot
		}

		return nil
	}

	public func addChunk(_ chunk: Chunk) -> Int {
		let offset = analysisModule.symbols[chunk.symbol]!.slot
		compiledChunks.append(chunk)
		return offset
	}

	// If a function named "main" isn't provided, we generate one that just runs all of the files
	// that were compiled in the module.
	func synthesizeMain() -> Chunk {
		let main = Chunk(name: "main", symbol: .function(name, "main", [], namespace: []), path: "<main>")

		for fileChunk in fileChunks {
			let offset = analysisModule.symbols[fileChunk.symbol]!.slot

			main.emit(opcode: .callChunkID, line: UInt32(offset))
			main.emit(byte: Byte(offset), line: UInt32(offset))
		}

		main.emit(opcode: .return, line: UInt32(fileChunks.count))

		return main
	}
}
