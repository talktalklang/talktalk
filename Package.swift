// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "TalkTalk",
	platforms: [.macOS(.v14), .iOS(.v13)],
	products: [
		.library(
			name: "TalkTalk",
			targets: ["TalkTalk"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
//		.package(url: "https://github.com/nakajima/C_LLVM", branch: "main")
		.package(path: "../LLVM")
	],
	targets: [
		.executableTarget(
			name: "talk",
			dependencies: [
				"TalkTalk",
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				"TalkTalkCompiler",
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
				"TalkTalkSyntax"
			]
		),
		.target(
			name: "TalkTalkCompiler",
			dependencies: [
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				.product(name: "LLVM", package: "LLVM")
			]
		),
		.target(
			name: "TalkTalk",
			dependencies: [
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
			]
		),
		.testTarget(
			name: "TalkTalkTests",
			dependencies: ["TalkTalk"]
		),
		.testTarget(
			name: "TalkTalkCompilerTests",
			dependencies: [
				"TalkTalkCompiler",
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				.product(name: "LLVM", package: "LLVM")
			]
		),
		.testTarget(
			name: "TalkTalkAnalysisTests",
			dependencies: ["TalkTalkAnalysis", "TalkTalkSyntax"]
		),
		.testTarget(
			name: "TalkTalkSyntaxTests",
			dependencies: ["TalkTalkSyntax"]
		)
	]
)

#if os(Linux)
	package.dependencies.append(
		.package(url: "https://github.com/apple/swift-testing", branch: "main")
	)

	for target in package.targets.filter(\.isTest) {
		target.dependencies.append(.product(name: "Testing", package: "swift-testing"))
	}
#endif
