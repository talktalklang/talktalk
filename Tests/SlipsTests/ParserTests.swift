//
//  ParserTests.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import Testing
import Slips

struct ParserTests {
	func parse(_ source: String) -> Expr {
		let lexer = Lexer(source)
		var parser = Parser(lexer)
		let result = parser.parse()
		for (token, message) in parser.errors {
			print("Error at \(token): \(message)")
		}
		return result
	}

	@Test("Basic expr") func expr() {
		if let ast = parse("(+ 1 2)") as? VariadicExpr {
			#expect(type(of: ast) == VariadicExpr.self)
			#expect(ast.op.lexeme == "+")
		} else {
			print("nope")
		}
	}

	@Test("def expr") func def() {
		let ast = parse("(def sum (+ x y))") as! DefExpr
		#expect(ast.name.lexeme == "sum")
	}
}
