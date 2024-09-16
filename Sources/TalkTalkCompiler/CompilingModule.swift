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
	var compiledChunks: [Symbol: Chunk] = [:]

	// The chunks created for each file being compiled. We can use these to synthesize a main function
	// if none exists.
	var fileChunks: [Chunk] = []

	// Lazy initializers for globals
	var valueInitializers: [Symbol: Chunk] = [:]

	// Top level structs for this module
	var structs: [Symbol: Struct] = [:]
	var structMethods: [Symbol: [Symbol: Chunk]] = [:]

	// Top level enums for this module
	var enums: [Symbol: Enum] = [:]

	// The available modules for import
	let moduleEnvironment: [String: Module]

	public init(name: String, analysisModule: AnalysisModule, moduleEnvironment: [String: Module]) {
		self.name = name
		self.analysisModule = analysisModule
		self.moduleEnvironment = moduleEnvironment
	}

	public func finalize(mode: CompilationMode) throws -> Module {
		var chunks: [Symbol: StaticChunk] = [:]
		var moduleStructs: [Symbol: Struct] = [:]

		for (symbol, info) in analysisModule.symbols {
			if info.isBuiltin { continue }

			switch symbol.kind {
			case .protocol: ()
			case .function:
				if let chunk = compiledChunks[symbol] {
					chunks[info.symbol] = StaticChunk(chunk: chunk)
					continue
				}

				// Copy the external method into our chunks, using the slot we want
				if case let .external(name) = info.source,
				   let module = moduleEnvironment[name],
				   let moduleInfo = module.symbols[symbol]
				{
					chunks[symbol] = module.chunks[moduleInfo.symbol]
					continue
				}

				throw CompilerError.chunkMissing("could not find compiled chunk for: \(symbol.description)")
			case let .method(typeName, name, params):
				if typeName == nil {
					// This is a protocol requirement, so its chunk will be supplied by whatever concrete type implements it.
					continue
				}

				if let chunk = compiledChunks[symbol] {
					chunks[info.symbol] = StaticChunk(chunk: chunk)
					continue
				}

				// Copy the external method into our chunks, using the slot we want
				if case let .external(name) = info.source,
					 let module = moduleEnvironment[name],
					 let moduleInfo = module.symbols[symbol]
				{
					chunks[symbol] = module.chunks[moduleInfo.symbol]
					continue
				}
			case let .struct(structName):
				switch info.source {
				case let .external(name):
					guard let module = moduleEnvironment[name], module.symbols[symbol] != nil else {
						continue
					}

					moduleStructs[info.symbol] = module.structs[symbol]

					// Import the struct's methods as well.
					for (sym, chunk) in module.chunks {
						if case let .method(name, _, _) = sym.kind, name == structName {
							chunks[sym] = chunk
						}
					}
				case .internal:
					guard let structType = structs[symbol] else {
						throw CompilerError.unknownIdentifier("could not find struct for: \(symbol.description)")
					}

					moduleStructs[info.symbol] = structType

					for method in structType.methods {
						chunks[method.symbol] = method
					}
				}
			case .enum:
				switch info.source {
				case let .external(name):
					guard let module = moduleEnvironment[name],
					      let moduleInfo = module.symbols[symbol]
					else {
						continue
					}

					enums[info.symbol] = module.enums[moduleInfo.symbol]
				case .internal:
					guard let enumType = enums[info.symbol] else {
						throw CompilerError.unknownIdentifier("could not find enum for: \(symbol.description)")
					}

					enums[info.symbol] = enumType
				}
			case .value(_), .primitive, .genericType(_), .property:
				()
			}
		}

		var module = Module(name: name, main: nil, symbols: analysisModule.symbols)

		// Copy over any other chunks that might be missing
		for (symbol, chunk) in compiledChunks {
			if chunks[symbol] == nil {
				chunks[symbol] = StaticChunk(chunk: chunk)
			}
		}

		// Set the module level function chunks
		module.chunks = chunks
		module.structs = moduleStructs

		// Set the module level enums
		module.enums = enums

		if mode == .executable {
			// If we're in executable compilation mode, we need an entry point. If we already have a func named "main" then
			// we can use that. Otherwise synthesize one out of the files in the module.
			if let existingMain = chunks.first(where: { $0.value.name == "main" }) {
				module.main = existingMain.value
			} else {
				let synthesized = try synthesizeMain()
				module.chunks[synthesized.symbol] = StaticChunk(chunk: synthesized)
				module.main = StaticChunk(chunk: synthesized)
			}
		}

		// Copy lazy value initializers
		for (name, chunk) in valueInitializers {
			guard let symbol = analysisModule.symbols[name] else {
				throw CompilerError.unknownIdentifier("No symbol found for \(name)")
			}

			module.valueInitializers[symbol.symbol] = StaticChunk(chunk: chunk)
		}

		return module
	}

	public func compile(file: AnalyzedSourceFile) throws -> Chunk {
		var compiler = SourceFileCompiler(name: file.path, module: name, analyzedSyntax: file.syntax, path: file.path)
		let chunk = try compiler.compile(in: self)
		compiledChunks[chunk.symbol] = chunk
		fileChunks.append(chunk)
		return chunk
	}

	// Get an offset for a global by name. If we already have it (it's been compiled) then just
	// return what we have. Otherwise, figure out what the offset will be and return that.
	//
	// If the analysis says that we don't have a global by this name, return nil.
	public func moduleFunctionOffset(for string: String) -> Int? {
		if let symbol = analysisModule.moduleFunctions[string]?.symbol,
		   let info = analysisModule.symbols[symbol]
		{
			return info.slot
		}

		return nil
	}

	public func moduleEnumOffset(for string: String) -> Int? {
		for (symbol, info) in analysisModule.symbols {
			if case .enum(string) = symbol.kind {
				return info.slot
			}
		}

		return nil
	}

	public func moduleValueOffset(for string: String) -> Int? {
		for (symbol, info) in analysisModule.symbols {
			if case .value(string) = symbol.kind {
				return info.slot
			}
		}

		return nil
	}

	public func addChunk(_ chunk: Chunk) throws -> Int {
		guard let offset = analysisModule.symbols[chunk.symbol]?.slot else {
			throw CompilerError.analysisError("No analysis symbol found for \(chunk.symbol)")
		}

		compiledChunks[chunk.symbol] = chunk
		return offset
	}

	// If a function named "main" isn't provided, we generate one that just runs all of the files
	// that were compiled in the module.
	func synthesizeMain() throws -> Chunk {
		let main = Chunk(name: "main", symbol: .function(name, "main", []), path: "<main>")

		for fileChunk in fileChunks {
			guard let offset = analysisModule.symbols[fileChunk.symbol]?.slot else {
				throw CompilerError.analysisError("could not find symbol for: \(fileChunk.symbol.description)")
			}

			main.emit(.opcode(.callChunkID), line: UInt32(offset))
			main.emit(.symbol(fileChunk.symbol), line: UInt32(offset))
		}

		main.emit(.opcode(.returnValue), line: UInt32(fileChunks.count))

		return main
	}
}
