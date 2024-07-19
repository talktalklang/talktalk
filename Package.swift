// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "TalkTalk",
	platforms: [.macOS(.v14)],
	products: [
		.executable(
			name: "tlk",
			targets: ["tlk"]
		),
		.library(
			name: "TalkTalk",
			targets: ["TalkTalk"]
		),
		.library(
			name: "TalkTalkTyper",
			targets: ["TalkTalkTyper"]
		),
		.library(
			name: "TalkTalkCompiler",
			targets: ["TalkTalkCompiler"]
		),
		.library(
			name: "TalkTalkInterpreter",
			targets: ["TalkTalkInterpreter"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
//		.package(url: "https://github.com/llvm-swift/LLVMSwift", branch: "master")
//		.package(url: "https://github.com/nakajima/C_LLVM", branch: "main"),
		.package(path: "../C_LLVM")
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		.executableTarget(
			name: "tlk",
			dependencies: [
				"TalkTalk",
				"TalkTalkSyntax",
				"TalkTalkTyper",
				"TalkTalkCompiler",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]
		),
		.target(
			name: "TalkTalkInterpreter"
		),
		.target(
			name: "TalkTalkCompiler",
			dependencies: [
				"TalkTalkSyntax",
				"TalkTalkTyper",
				"C_LLVM",
			]
		),
		.target(
			name: "TalkTalkSyntax"
		),
		.target(
			name: "TalkTalkTyper",
			dependencies: [
				"TalkTalkSyntax",
			]
		),
		.target(
			name: "TalkTalk",
			resources: [
				.process("StandardLibrary/Array.tlk"),
			],
			swiftSettings: [
				.define("DEBUGGING", .when(configuration: .debug)),
			]
		),
		.testTarget(
			name: "TalkTalkTests",
			dependencies: [
				"TalkTalk",
			],
			swiftSettings: [
				.enableUpcomingFeature("SwiftTesting"),
			]
		),
		.testTarget(
			name: "TalkTalkCompilerTests",
			dependencies: [
				"TalkTalkCompiler",
			],
			swiftSettings: [
				.enableUpcomingFeature("SwiftTesting"),
			]
		),
		.testTarget(
			name: "TalkTalkInterpreterTests",
			dependencies: [
				"TalkTalkInterpreter",
			],
			swiftSettings: [
				.enableUpcomingFeature("SwiftTesting"),
			]
		),
		.testTarget(
			name: "TalkTalkSyntaxTests",
			dependencies: [
				"TalkTalkSyntax",
			],
			swiftSettings: [
				.enableUpcomingFeature("SwiftTesting"),
			]
		),
		.testTarget(
			name: "TalkTalkTyperTests",
			dependencies: ["TalkTalkTyper"],
			swiftSettings: [
				.enableUpcomingFeature("SwiftTesting"),
			]
		),
	],
	cxxLanguageStandard: .cxx20
)

#if os(Linux)
	package.dependencies.append(
		.package(url: "https://github.com/apple/swift-testing", branch: "main")
	)

	for target in package.targets.filter({ $0.isTest }) {
		target.dependencies.append(.product(name: "Testing", package: "swift-testing"))
	}
#endif
