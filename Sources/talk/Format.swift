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

	@Argument(help: "The input to format.")
	var input: String

	func run() async throws {
		let source = try get(input: input).text
		let formatted = Formatter.format(source)
		print(formatted)
	}
}
