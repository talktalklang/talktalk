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
		.package(url: "https://github.com/nakajima/C_LLVM", branch: "main")
	],
	targets: [
		.executableTarget(
			name: "talk",
			dependencies: ["TalkTalk"]
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
				.product(name: "LLVM", package: "C_LLVM")
			]
		),
		.target(
			name: "TalkTalk",
			dependencies: [
				"TalkTalkSyntax",
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
				"TalkTalkAnalysis"
			]
		),
		.testTarget(
			name: "TalkTalkAnalysisTests",
			dependencies: ["TalkTalkAnalysis"]
		),
		.testTarget(
			name: "TalkTalkSyntaxTests",
			dependencies: []
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
