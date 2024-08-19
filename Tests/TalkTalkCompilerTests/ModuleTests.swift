//
//  ModuleTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

import Foundation
import TalkTalkAnalysis
import TalkTalkBytecode
import TalkTalkCompiler
import TalkTalkSyntax
import Testing

@MainActor
struct ModuleTests {
	func compile(
		name: String,
		_ files: [ParsedSourceFile],
		analysisEnvironment: [String: AnalysisModule] = [:],
		moduleEnvironment: [String: Module] = [:]
	) -> (Module, AnalysisModule) {
		let analysis = moduleEnvironment.reduce(into: [:]) { res, tup in res[tup.key] = analysisEnvironment[tup.key] }
		let analyzed = try! ModuleAnalyzer(name: name, files: Set(files), moduleEnvironment: analysis, importedModules: Array(analysis.values)).analyze()
		let module = try! ModuleCompiler(name: name, analysisModule: analyzed, moduleEnvironment: moduleEnvironment).compile(mode: .executable)
		return (module, analyzed)
	}

	@Test("Serialization/Deserialization") func encode() throws {
		let (module, analysis) = compile(name: "Encoding", [.tmp("func foo() { 123 }"), .tmp("func main() { foo() }")])
		let serialized = try module.serialize(with: analysis, with: JSONEncoder())
		let deserializedModule = try Module.deserialize(from: serialized, with: JSONDecoder())

		#expect(module.name == deserializedModule.name)
		#expect(module.main == deserializedModule.main)
		#expect(module.chunks == deserializedModule.chunks)
		#expect(module.symbols == deserializedModule.symbols)
		#expect(module.valueInitializers == deserializedModule.valueInitializers)
	}
}
