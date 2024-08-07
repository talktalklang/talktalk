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
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
	],
	targets: [
		.executableTarget(
			name: "talk",
			dependencies: [
				"TalkTalk",
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				.product(name: "ArgumentParser", package: "swift-argument-parser")
			]
		),
		.target(
			name: "TalkTalkSyntax",
			dependencies: []
		),
		.target(
			name: "TalkTalkAnalysis",
			dependencies: [
				"TalkTalkSyntax",
				"TalkTalkBytecode"
			]
		),
	//	.target(
	//		name: "TalkTalkLLVMExperimental",
	//		dependencies: [
	//			"TalkTalkSyntax",
	//			"TalkTalkAnalysis",
	//			"LLVM"
	//		]
	//	),
	//	.target(
	//		name: "LLVM",
	//		dependencies: ["C_LLVM"]
	//	),
	//	.systemLibrary(
	//		name: "C_LLVM",
	//		pkgConfig: "cllvm",
	//		providers: [
	//			.brew(["llvm"])
	//		]
	//	),
		.target(
			name: "TalkTalk",
			dependencies: [
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				"TalkTalkCompiler",
				"TalkTalkBytecode",
				"TalkTalkVM",
				"TalkTalkLSP"
			]
		),
		.target(
			name: "TalkTalkLSP",
			dependencies: [
				"TalkTalkBytecode",
				"TalkTalkAnalysis"
			]
		),
		.target(
			name: "TalkTalkCompiler",
			dependencies: [
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				"TalkTalkBytecode"
			]
		),
		.target(
			name: "TalkTalkVM",
			dependencies: [
				"TalkTalkCompiler",
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
				"TalkTalkBytecode"
			]
		),
		.target(
			name: "TalkTalkBytecode"
		),
		.testTarget(
			name: "TalkTalkTests",
			dependencies: ["TalkTalk"]
		),
		.testTarget(
			name: "TalkTalkBytecodeTests",
			dependencies: ["TalkTalkBytecode"]
		),
	//	.testTarget(
	//		name: "TalkTalkLLVMExperimentalTests",
	//		dependencies: [
	//			"TalkTalkLLVMExperimental",
	//			"TalkTalkSyntax",
	//			"TalkTalkAnalysis",
	//			"LLVM"
	//		]
	//	),
		.testTarget(
			name: "TalkTalkLSPTests",
			dependencies: [
				"TalkTalkLSP",
				"TalkTalkBytecode",
				"TalkTalkAnalysis",
				"TalkTalkSyntax"
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
				"TalkTalkVM",
				"TalkTalkCompiler",
				"TalkTalkSyntax",
				"TalkTalkAnalysis",
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
