//
//  AST.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
import ArgumentParser
import Foundation
import TalkTalkSyntax

struct AST: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Print the AST for the given input"
	)

	@Argument(help: "The input to parse.", completion: .file(extensions: [".tlk"]))
	var input: String

	func run() async throws {
		let source = try get(input: input)
		let parsed = try Parser.parse(source)
		let formatted = try ASTPrinter.format(parsed)
		print(formatted)
	}
}
