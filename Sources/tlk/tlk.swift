//
//  tlk.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

import ArgumentParser
@testable import TalkTalk

@main
struct TlkCommand: ParsableCommand {
//	@Argument(help: "The input to run.")
//	var input: String?
//
//	@Flag(help: "Just print the tokens") var tokenize: Bool = false

	mutating func run() throws {
		var chunk = Chunk()
		chunk.write(value: 2, line: 1)
		chunk.write(value: 3, line: 1)

		chunk.write(.multiply, line: 2)

		chunk.write(value: 6, line: 3)
		chunk.write(.divide, line: 4)

		chunk.write(.return, line: 5)

		var vm = TalkTalk.VM(chunk: chunk)
		print(vm.run())
	}
}
