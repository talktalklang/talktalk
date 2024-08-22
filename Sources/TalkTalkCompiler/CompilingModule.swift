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

		// Reserve offsets for module functions
//		var i = 0
//		for (_, global) in analysisModule.moduleFunctions.sorted(by: { $0.key < $1.key }) {
//			functionSymbols[.function(global.name)] = i++
//		}
//
//		// Reserve offsets for file functions
//		for file in analysisModule.analyzedFiles {
//			functionSymbols[.function(file.path)] = i++
//		}
//
//		// Reserve offsets for module values
//		for (i, (_, global)) in analysisModule.values.sorted(by: { $0.key < $1.key }).enumerated() {
//			valueSymbols[.value(global.name)] = i
//		}
//
//		// Reserve offsets for struct values
//		for (i, (_, structT)) in analysisModule.structs.sorted(by: { $0.key < $1.key }).enumerated() {
//			valueSymbols[.struct(structT.name)] = i
//
//			// Reserve offsets for struct methods
//			for (j, (methodName, method)) in structT.methods.enumerated() {
//				functionSymbols[.method(structT.name, methodName, method.params.map(\.name))] = j
//			}
//		}
	}

	public func finalize(mode: CompilationMode) -> Module {
		let chunkCount = analysisModule.moduleFunctions.values.count(where: { $0.isImport }) + compiledChunks.count // + analysisModule.files.count
		var chunks: [StaticChunk] = Array(repeating: StaticChunk(chunk: .init(name: "_", symbol: .function(name, "_", [], namespace: []))), count: chunkCount)
		var main: StaticChunk? = nil
		var moduleStructs: [Struct] = Array(repeating: Struct(name: "_", propertyCount: 0), count: structs.count)

		if mode == .executable {
			// If we're in executable compilation mode, we need an entry point. If we already have a func named "main" then
			// we can use that. Otherwise synthesize one out of the files in the module.
			if let existingMain = chunks.first(where: { $0.name == "main" }) {
				main = existingMain
			} else {
				let synthesized = synthesizeMain()
				chunks.append(.init(chunk: synthesized))
				main = StaticChunk(chunk: synthesized)
			}
		}

		var module = Module(name: name, main: main, symbols: analysisModule.symbols)

		for (symbol, info) in analysisModule.symbols {
			switch symbol.kind {
			case .function:
				if let chunk = compiledChunks.first(where: { $0.symbol == symbol }) {
					chunks[info.slot] = StaticChunk(chunk: chunk)
					continue
				}

				if case let .external(name) = info.source,
					 let module = moduleEnvironment[name],
					 let moduleInfo = module.symbols[symbol] {
					chunks[info.slot] = module.chunks[moduleInfo.slot]
					continue
				}

				fatalError("could not find compiled chunk for: \(symbol.description)")
			case .method:
				guard let chunk = compiledChunks.first(where: { $0.symbol == symbol }) else {
					fatalError("could not find compiled chunk for: \(symbol.description)")
				}

				chunks[info.slot] = StaticChunk(chunk: chunk)
			case .property:
				() // Nothing to do here
			case .struct:
				guard let structType = structs[symbol] else {
					fatalError("could not find struct for: \(symbol.description)")
				}

				moduleStructs[info.slot] = structType
			case .value(_), .primitive:
				()
			}
		}

		// Set the module level function chunks
		module.chunks = chunks

		module.structs = moduleStructs

//		// Set offets for moduleFunction values
//		for (i, _) in module.chunks.enumerated() {
//			module.functions[Byte(i)] = .moduleFunction(Value.IntValue(i))
//		}

		// Copy lazy value initializers
		for (name, chunk) in valueInitializers {
			let symbol = analysisModule.symbols[name]!
			module.valueInitializers[Byte(symbol.slot)] = StaticChunk(chunk: chunk)
		}

		return module
	}

	public func compile(file: AnalyzedSourceFile) throws -> Chunk {
		var compiler = SourceFileCompiler(name: file.path, module: name, analyzedSyntax: file.syntax)
		let chunk = try compiler.compile(in: self)
		compiledChunks.append(chunk)
		fileChunks.append(chunk)
		return chunk
	}

	// Get an offset for a global by name. If we already have it (it's been compiled) then just
	// return what we have. Otherwise, figure out what the offset will be and return that.
	//
	// If the analysis says that we don't have a global by this name, return nil.
	public func moduleFunctionOffset(for symbol: Symbol) -> Int? {
		if case .function = symbol.kind {
			return analysisModule.symbols[symbol]?.slot
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
		let main = Chunk(name: "main", symbol: .function(name, "main", [], namespace: []))

		for fileChunk in fileChunks {
			let offset = analysisModule.symbols[fileChunk.symbol]!.slot

			main.emit(opcode: .callChunkID, line: UInt32(offset))
			main.emit(byte: Byte(offset), line: UInt32(offset))
		}

		main.emit(opcode: .return, line: UInt32(fileChunks.count))

		return main
	}
}
