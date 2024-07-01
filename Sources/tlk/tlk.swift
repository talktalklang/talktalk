//
//  tlk.swift
//  
//
//  Created by Pat Nakajima on 6/30/24.
//

import ArgumentParser
import TalkTalk

@main
struct TlkCommand: ParsableCommand {
//	@Argument(help: "The input to run.")
//	var input: String?
//
//	@Flag(help: "Just print the tokens") var tokenize: Bool = false

	mutating func run() throws {
		TalkTalk.VM().main()
	}
}
