//
//  ProtocolTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//

import Testing
import TalkTalkSyntax
@testable import TypeChecker

struct ProtocolTests {
	func infer(_ expr: [any Syntax]) throws -> InferenceContext {
		return try Inferencer(imports: []).infer(expr).solve()
	}

	@Test("Types protocol decl") func protocolType() throws {
		let syntax = try Parser.parse(
			"""
			protocol Greetable {
				func greet() -> String
			}
			"""
		)

		let context = try infer(syntax)

		#expect(context[syntax[0]] == .type(.protocol(ProtocolType(name: "Greetable"))))
	}
}
