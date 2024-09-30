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
				"TalkTalkAnalysis",
				"TalkTalkDriver",
				"TalkTalkVM",
				"TypeChecker",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]
		),
		.target(
			name: "TalkTalkAnalysis",
			dependencies: [
				"TalkTalkCore",
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
				"TalkTalkCore",
				"TypeChecker",
			]
		),
		.target(
			name: "TalkTalkCompiler",
			dependencies: [
				"TalkTalkCore",
				"TalkTalkAnalysis",
				"TalkTalkBytecode",
				.product(name: "OrderedCollections", package: "swift-collections"),
			]
		),
		.target(
			name: "TalkTalkDriver",
			dependencies: [
				"TalkTalkCore",
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
				"TalkTalkAnalysis",
				"TalkTalkBytecode",
				"TalkTalkDriver",
				"TalkTalkCore",
				.product(name: "OrderedCollections", package: "swift-collections"),
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
				"TalkTalkCompiler",
			]
		),
		.testTarget(
			name: "TalkTalkBytecodeTests",
			dependencies: [
				"TalkTalkBytecode",
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
			]
		),
		.testTarget(
			name: "TalkTalkCompilerTests",
			dependencies: [
				"TalkTalkCompiler",
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
				"TalkTalkAnalysis",
			]
		),
		.testTarget(
			name: "TalkTalkAnalysisTests",
			dependencies: ["TalkTalkAnalysis", "TalkTalkCore"]
		),
		.testTarget(
			name: "TalkTalkSyntaxTests",
			dependencies: ["TalkTalkCore"]
		),
		.testTarget(
			name: "TypeCheckerTests",
			dependencies: [
				"TypeChecker",
				"TalkTalkCore",
			]
		),
	]
)

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
