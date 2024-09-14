//
//  Format.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
import ArgumentParser
import Foundation
import TalkTalkSyntax

struct Format: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Format the given input"
	)

	@ArgumentParser.Argument(help: "The input to format.", completion: .file(extensions: [".tlk"]))
	var input: String

	func run() async throws {
		let source = try get(input: input).text
		let formatted = try OldFormatter.format(source)
		print(formatted)
	}
}
