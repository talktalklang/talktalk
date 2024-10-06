//
//  Format.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
import ArgumentParser
import TalkTalkCore
import Foundation

struct Format: TalkTalkCommand {
	static let configuration = CommandConfiguration(
		abstract: "Format the given input"
	)

	@ArgumentParser.Argument(help: "The input to format.", completion: .file(extensions: [".talk"]))
	var input: String

	func run() async throws {
		print(URL.currentDirectory())
		let source = try get(input: input)
		let formatted = try Formatter(input: source).format()
		print(formatted)
	}
}
