//
//  ProtocolTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//

import TalkTalkSyntax
import Testing
@testable import TypeChecker

struct ProtocolTests {
	func infer(_ expr: [any Syntax]) throws -> InferenceContext {
		try Inferencer(imports: []).infer(expr).solve()
	}

	@Test("Types protocol decl") func protocolType() throws {
		let syntax = try Parser.parse(
			"""
			protocol Greetable {
				var name: String

				func greet() -> String
			}
			"""
		)

		let context = try infer(syntax)

		let protocolType = ProtocolType.extract(from: context[syntax[0]]!.asType(in: context))!
		#expect(protocolType.name == "Greetable")
		#expect(protocolType.properties["name"] == .type(.base(.string)))
		#expect(protocolType.methods["greet"] == .scheme(Scheme(name: "greet", variables: [], type: .function([], .base(.string)))))
	}

	@Test("Types protocol method", .disabled("Waitin for instantiatable refactor")) func protocolMethod() throws {
		let syntax = try Parser.parse(
			"""
			protocol Greetable {
				func greet() -> String
			}

			func greetGreetable(greetable: Greetable) {
				greetable.greet()
			}
			"""
		)

		let context = try infer(syntax)
		#expect(context.errors.isEmpty)

		let fn = context[syntax[1]]!.asType(in: context)

		#expect(fn == .function([
			// TODO.
		], .base(.string)))
	}
}
