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
	var compiledChunks: [Chunk] = []

	// Stores globals with their offsets. This is useful for allowing us to calculate an offset
	// for a global before it's been resolved.
	var functionSymbols: [Symbol: Int] = [:]

	var valueSymbols: [Symbol: Int] = [:]

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
		var i = 0
		for (_, global) in analysisModule.moduleFunctions.sorted(by: { $0.key < $1.key }) {
			functionSymbols[.function(global.name)] = i++
		}

		// Reserve offsets for file functions
		for file in analysisModule.analyzedFiles {
			functionSymbols[.function(file.path)] = i++
		}

		// Reserve offsets for module values
		for (i, (_, global)) in analysisModule.values.sorted(by: { $0.key < $1.key }).enumerated() {
			valueSymbols[.value(global.name)] = i
		}

		// Reserve offsets for struct values
		for (i, (_, structT)) in analysisModule.structs.sorted(by: { $0.key < $1.key }).enumerated() {
			valueSymbols[.struct(structT.name)] = i

			// Reserve offsets for struct methods
			for (j, (methodName, method)) in structT.methods.enumerated() {
				functionSymbols[.method(structT.name, methodName, method.params.map(\.key))] = j
			}
		}
	}

	public func finalize(mode: CompilationMode) -> Module {
		let chunkCount = analysisModule.moduleFunctions.values.count(where: { $0.isImport }) + compiledChunks.count //+ analysisModule.files.count
		var chunks: [StaticChunk] = Array(repeating: StaticChunk(chunk: .init(name: "_")), count: chunkCount)

		// Copy chunks for imported functions into our module (at some point it'd be nice to just be able to call into those
		// but we'll get there..)
		for (name, global) in analysisModule.moduleFunctions where global.isImport {
			guard case let .external(analysis) = global.source else {
				fatalError("attempted to import symbol from non-external module")
			}

			guard let module = moduleEnvironment[analysis.name], let moduleOffset = module.symbols[.function(name)] else {
				fatalError("\(analysis.name) not found in module environment")
			}

			guard let offset = moduleFunctionOffset(for: name) else {
				fatalError("no offset registered for imported symbol: \(name)")
			}

			chunks[offset] = module.chunks[moduleOffset]
		}

		// Go through the list of global chunks, sort by offset, add to the real module
		for chunk in compiledChunks {
			let offset = functionSymbols[.function(chunk.name)]!
			chunks[offset] = StaticChunk(chunk: chunk)
		}

		var main: StaticChunk? = nil

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

		var module = Module(name: name, main: main, symbols: functionSymbols)

		// Set the module level function chunks
		module.chunks = chunks

		// Set offets for moduleFunction values
		for (i, _) in module.chunks.enumerated() {
			module.functions[Byte(i)] = .moduleFunction(Value.IntValue(i))
		}

		// Copy lazy value initializers
		for (name, chunk) in valueInitializers {
			module.valueInitializers[Byte(valueSymbols[name]!)] = StaticChunk(chunk: chunk)
		}

		let foundStructs = analysisModule.structs.map { (name, astruct) in
			if let internalStruct = structs.first(where: { $0.value.name == name }) {
				// If we've already got it, just return it
				return internalStruct
			} else if case let .external(module) = astruct.source,
								let module = moduleEnvironment[module.name],
								let importStruct = module.structs.first(where: { $0.name == name }) {
				// If we don't, we need to import it
				return (.struct(name), importStruct)
			} else {
				fatalError("could not find compiled struct named \(name)")
			}
		}

		// Copy struct types, sorting by their index in the symbols table
		for case (.struct(let name), var structType) in foundStructs.sorted(by: { valueSymbols[$0.key]! < valueSymbols[$1.key]! }) {
			// Copy struct methods, sorting by their index in the symbols table
			let methods = structMethods[.struct(name)] ?? [:]
			for case let (.method(_, _, _), chunk) in methods.sorted(by: { functionSymbols[$0.key]! < functionSymbols[$1.key]! }) {
				structType.methods.append(StaticChunk(chunk: chunk))
			}

			module.structs.append(structType)
		}

		return module
	}

	public func compile(file: AnalyzedSourceFile) throws {
		var compiler = SourceFileCompiler(name: file.path, analyzedSyntax: file.syntax)
		let chunk = try compiler.compile(in: self)
		compiledChunks.append(chunk)
		fileChunks.append(chunk)
	}

	// Get an offset for a global by name. If we already have it (it's been compiled) then just
	// return what we have. Otherwise, figure out what the offset will be and return that.
	//
	// If the analysis says that we don't have a global by this name, return nil.
	public func moduleFunctionOffset(for name: String) -> Int? {
		return functionSymbols[.function(name)]
	}

	public func moduleValueOffset(for name: String) -> Int? {
		return valueSymbols[.value(name)]
	}

	public func addChunk(_ chunk: Chunk) -> Int {
		let offset = functionSymbols[.function(chunk.name), default: functionSymbols.count]
		functionSymbols[.function(chunk.name)] = offset
		compiledChunks.append(chunk)
		return offset
	}

	// If a function named "main" isn't provided, we generate one that just runs all of the files
	// that were compiled in the module.
	func synthesizeMain() -> Chunk {
		let main = Chunk(name: "main")

		for fileChunk in fileChunks {
			let offset = functionSymbols[.function(fileChunk.name)]!

			main.emit(opcode: .callChunkID, line: UInt32(offset))
			main.emit(byte: Byte(offset), line: UInt32(offset))
		}

		main.emit(opcode: .return, line: UInt32(fileChunks.count))

		return main
	}
}
