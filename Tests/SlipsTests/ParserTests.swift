//
//  ParserTests.swift
//  
//
//  Created by Pat Nakajima on 7/22/24.
//

import Testing
import Slips

struct ParserTests {
	func parse(_ source: String) -> any ASTNode {
		var lexer = Lexer(source)
		var parser = Parser(lexer)
		return parser.parse()
	}

	@Test("Basic expr") func expr() {
		let ast = parse("(+ 1 2)")
		
	}
}
