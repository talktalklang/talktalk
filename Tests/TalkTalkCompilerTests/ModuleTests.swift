//
//  ModuleTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import Testing
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkSyntax
import TalkTalkAnalysis
import Foundation
import MessagePack

@MainActor
struct ModuleTests {
	func compile(
		name: String,
		_ files: [ParsedSourceFile],
		analysisEnvironment: [String: AnalysisModule] = [:],
		moduleEnvironment: [String: Module] = [:]
	) -> (Module, AnalysisModule) {
		let analysis = moduleEnvironment.reduce(into: [:]) { res, tup in res[tup.key] = analysisEnvironment[tup.key] }
		let analyzed = try! ModuleAnalyzer(name: name, files: files, moduleEnvironment: analysis).analyze()
		let module = try! ModuleCompiler(name: name, analysisModule: analyzed, moduleEnvironment: moduleEnvironment).compile(mode: .executable)
		return (module, analyzed)
	}

	@Test("Serialization/Deserialization") func encode() throws {
		let (module, analysis) = compile(name: "Encoding", [.tmp("func foo() { 123 }"), .tmp("func main() { foo() }")])
		let serialized = try module.serialize(with: analysis, with: JSONEncoder())
		let msgpackSerialized = try module.serialize(with: analysis, with: MessagePackEncoder())

		let deserializedModule = try Module.deserialize(from: serialized, with: JSONDecoder())
		let deserializedMsgpackModule = try Module.deserialize(from: msgpackSerialized, with: MessagePackDecoder())

		#expect(module.name == deserializedModule.name)
		#expect(module.main == deserializedModule.main)
		#expect(module.chunks == deserializedModule.chunks)
		#expect(module.symbols == deserializedModule.symbols)
		#expect(module.valueInitializers == deserializedModule.valueInitializers)

		#expect(module.name == deserializedMsgpackModule.name)
		#expect(module.main == deserializedMsgpackModule.main)
		#expect(module.chunks == deserializedMsgpackModule.chunks)
		#expect(module.symbols == deserializedMsgpackModule.symbols)
		#expect(module.valueInitializers == deserializedMsgpackModule.valueInitializers)
	}
}
