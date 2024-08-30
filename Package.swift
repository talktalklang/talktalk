// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "TalkTalk",
	platforms: [.macOS(.v14), .iOS(.v17)],
	products: [
		.library(
			name: "TalkTalkCore",
			targets: ["TalkTalkCore"]
		),
		.library(
			name: "TalkTalkSyntax",
			targets: ["TalkTalkSyntax"]
		),
		.library(
			name: "TypeChecker",
			targets: ["TypeChecker"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
	],
	targets: [
		.executableTarget(
			name: "talk",
			dependencies: [
				"TalkTalkCore",
				"TalkTalkLSP",
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				"TalkTalkDriver",
				"TalkTalkInterpreter",
				"TalkTalkVM",
				"TypeChecker",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]
		),
		.target(
			name: "TalkTalkSyntax",
			dependencies: []
		),
		.target(
			name: "TalkTalkAnalysis",
			dependencies: [
				"TalkTalkCore",
				"TalkTalkSyntax",
				"TalkTalkBytecode",
				"TypeChecker"
			]
		),
		.target(
			name: "TalkTalkCore",
			dependencies: [],
			resources: [
				.copy("../../Library/Standard"),
			]
		),
		.target(
			name: "TypeChecker",
			dependencies: [
				"TalkTalkSyntax"
			]
		),
		.target(
			name: "TalkTalkLSP",
			dependencies: [
				"TalkTalkBytecode",
				"TalkTalkAnalysis",
				"TalkTalkCompiler",
				"TalkTalkDriver",
				"TalkTalkSyntax",
				"TypeChecker"
			]
		),
		.target(
			name: "TalkTalkCompiler",
			dependencies: [
				"TalkTalkCore",
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				"TalkTalkBytecode"
			]
		),
		.target(
			name: "TalkTalkDriver",
			dependencies: [
				"TalkTalkCore",
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				"TalkTalkCompiler",
				"TalkTalkBytecode",
				"TypeChecker"
			]
		),
		.target(
			name: "TalkTalkVM",
			dependencies: [
				"TalkTalkCompiler",
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				"TalkTalkBytecode",
				"TalkTalkDriver",
			]
		),
		.target(
			name: "TalkTalkInterpreter",
			dependencies: [
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				"TalkTalkBytecode",
				"TypeChecker"
			]
		),
		.target(
			name: "TalkTalkBytecode"
		),
		.testTarget(
			name: "TalkTalkCoreTests",
			dependencies: [
				"TalkTalkCore",
				"TalkTalkDriver",
				"TalkTalkBytecode",
				"TalkTalkAnalysis",
				"TalkTalkSyntax",
				"TalkTalkCompiler",
			]
		),
		.testTarget(
			name: "TalkTalkBytecodeTests",
			dependencies: [
				"TalkTalkBytecode",
				"TalkTalkSyntax",
				"TalkTalkCompiler",
				"TalkTalkAnalysis",
			]
		),
		.testTarget(
			name: "TalkTalkLSPTests",
			dependencies: [
				"TalkTalkLSP",
				"TalkTalkBytecode",
				"TalkTalkAnalysis",
				"TalkTalkSyntax",
			]
		),
		.testTarget(
			name: "TalkTalkCompilerTests",
			dependencies: [
				"TalkTalkCompiler",
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
			]
		),
		.testTarget(
			name: "TalkTalkVMTests",
			dependencies: [
				"TalkTalkCore",
				"TalkTalkDriver",
				"TalkTalkVM",
				"TalkTalkCompiler",
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
			]
		),
		.testTarget(
			name: "TalkTalkInterpreterTests",
			dependencies: [
				"TalkTalkInterpreter",
			]
		),
		.testTarget(
			name: "TalkTalkAnalysisTests",
			dependencies: ["TalkTalkAnalysis", "TalkTalkSyntax"]
		),
		.testTarget(
			name: "TalkTalkSyntaxTests",
			dependencies: ["TalkTalkSyntax"]
		),
		.testTarget(
			name: "TypeCheckerTests",
			dependencies: [
				"TypeChecker",
				"TalkTalkSyntax"
			]
		)
	]
)

#if !canImport(Testing)
	package.dependencies.append(
		.package(url: "https://github.com/apple/swift-testing", branch: "main")
	)

	for target in package.targets.filter(\.isTest) {
		target.dependencies.append(.product(name: "Testing", package: "swift-testing"))
	}
#endif
