// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
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
			name: "TalkTalkBytecode",
			targets: ["TalkTalkBytecode"]
		),
		.library(
			name: "TalkTalkSyntax",
			targets: ["TalkTalkSyntax"]
		),
		.library(
			name: "TypeChecker",
			targets: ["TypeChecker"]
		),
		.library(
			name: "TalkTalkAnalysis",
			targets: ["TalkTalkAnalysis"]
		),
		.library(
			name: "TalkTalkCompiler",
			targets: ["TalkTalkCompiler"]
		),
		.library(
			name: "TalkTalkVM",
			targets: ["TalkTalkVM"]
		),
		.library(
			name: "TalkTalkLSP",
			targets: ["TalkTalkLSP"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
		.package(url: "https://github.com/apple/swift-collections", branch: "main"),
		.package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.56.2"),
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
			dependencies: [
				"TalkTalkCore",
			]
		),
		.target(
			name: "TalkTalkAnalysis",
			dependencies: [
				"TalkTalkCore",
				"TalkTalkSyntax",
				"TalkTalkBytecode",
				"TypeChecker",
				.product(name: "OrderedCollections", package: "swift-collections"),
			]
		),
		.target(
			name: "TalkTalkCore",
			dependencies: [],
			swiftSettings: [
				.define("WASM", .when(platforms: [.wasi])),
			]
		),
		.target(
			name: "TypeChecker",
			dependencies: [
				"TalkTalkCore",
				"TalkTalkSyntax",
				.product(name: "OrderedCollections", package: "swift-collections"),
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
				"TypeChecker",
			]
		),
		.target(
			name: "TalkTalkCompiler",
			dependencies: [
				"TalkTalkCore",
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				"TalkTalkBytecode",
				.product(name: "OrderedCollections", package: "swift-collections"),
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
				"TypeChecker",
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
				"TalkTalkCore",
				.product(name: "OrderedCollections", package: "swift-collections"),
			]
		),
		.target(
			name: "TalkTalkInterpreter",
			dependencies: [
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				"TalkTalkBytecode",
				"TypeChecker",
			]
		),
		.target(
			name: "TalkTalkBytecode",
			dependencies: [
				"TalkTalkCore",
				.product(name: "OrderedCollections", package: "swift-collections"),
			]
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
				"TalkTalkSyntax",
			]
		),
	]
)

for target in package.targets {
	target.swiftSettings?.append(.enableExperimentalFeature("StrictConcurrency"))
}

#if !WASM
	for target in package.targets {
		target.resources = [
			.copy("../../Library/Standard"),
		]
	}
#endif

#if os(Linux)
	package.dependencies.append(
		.package(url: "https://github.com/apple/swift-testing", branch: "main")
	)

	for target in package.targets.filter(\.isTest) {
		target.dependencies.append(.product(name: "Testing", package: "swift-testing"))
	}
#endif
