// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
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
			name: "Interpreter",
			targets: ["Interpreter"]
		),
		.library(
			name: "TalkTalkBytecode",
			targets: ["TalkTalkBytecode"]
		),
		.library(
			name: "TypeChecker",
			targets: ["TypeChecker"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
		.package(url: "https://github.com/apple/swift-collections", branch: "main"),
		.package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.56.2"),
	],
	targets: [
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
			name: "Interpreter",
			dependencies: [
				"TalkTalkCore",
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
				"TalkTalkBytecode",
			]
		),
		.testTarget(
			name: "TalkTalkBytecodeTests",
			dependencies: [
				"TalkTalkBytecode",
			]
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
		.testTarget(
			name: "InterpreterTests",
			dependencies: [
				"Interpreter",
				"TypeChecker",
				"TalkTalkCore",
			]
		),
	]
)

#if !WASM
	for target in package.targets {
		if target.name == "TalkTalkCore" {
			target.resources = [
				.copy("../../Library/Standard"),
			]
		}
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
