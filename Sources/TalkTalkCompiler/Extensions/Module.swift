//
//  Module.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import Foundation
import MessagePack
import TalkTalkAnalysis
import TalkTalkBytecode

public protocol ModuleEncoder {
	func encode<T>(_ value: T) throws -> Data where T: Encodable
}

public protocol ModuleDecoder {
	func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension JSONEncoder: ModuleEncoder {}
extension JSONDecoder: ModuleDecoder {}

extension MessagePackEncoder: ModuleEncoder {}
extension MessagePackDecoder: ModuleDecoder {}

public extension Module {
	// A helper for when we just want to run a chunk
	static func main(_ chunk: Chunk) -> Module {
		Module(name: "main", main: chunk, symbols: [:])
	}

	func serialize(with analysis: AnalysisModule, with encoder: any ModuleEncoder) throws -> [Byte] {
		let serializedAnalysis = SerializedAnalysisModule(analysisModule: analysis)
		let serializedModule = SerializedModule(
			analysis: serializedAnalysis,
			main: main,
			chunks: chunks,
			symbols: symbols,
			valueInitializers: valueInitializers
		)

		let data = try encoder.encode(serializedModule)
		return [Byte](data)
	}

	static func deserialize(from bytes: [Byte], with decoder: any ModuleDecoder) throws -> Module {
		let serializedModule = try decoder.decode(SerializedModule.self, from: Data(bytes))

		var module = Module(
			name: serializedModule.analysis.name,
			main: serializedModule.main,
			symbols: serializedModule.symbols
		)

		module.chunks = serializedModule.chunks
		module.valueInitializers = serializedModule.valueInitializers

		return module
	}
}
