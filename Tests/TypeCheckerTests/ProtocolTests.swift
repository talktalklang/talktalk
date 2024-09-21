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

	@Test("Types protocol method") func protocolMethod() throws {
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

		let protocolType = ProtocolType.extract(from: context[syntax[0]]!.asType(in: context))!
		let fn = context[syntax[1]]!.asType(in: context)

		#expect(fn == .function([
			.instance(.protocol(Instance(id: 0, type: protocolType, substitutions: [:]))),
		], .base(.string)))
	}

	@Test("Types protocol method without type annotations") func protocolMethodSansTypes() throws {
		let syntax = try Parser.parse(
			"""
			protocol Greetable {
				func greet(name: String) -> String
			}

			struct Person: Greetable {
				func greet(name) {
					"hi " + name
				}
			}
			"""
		)

		let context = try infer(syntax)
		#expect(context.errors.isEmpty)
	}

	@Test("Types protocol property") func protocolProperty() throws {
		let syntax = try Parser.parse(
			"""
			protocol Greetable {
				var name: String
			}

			func greetGreetable(greetable: Greetable) {
				greetable.name
			}
			"""
		)

		let context = try infer(syntax)
		#expect(context.errors.isEmpty)

		let protocolType = ProtocolType.extract(from: context[syntax[0]]!.asType(in: context))!
		let fn = context[syntax[1]]!.asType(in: context)

		#expect(fn == .function([
			.instance(.protocol(Instance(id: 0, type: protocolType, substitutions: [:]))),
		], .base(.string)))
	}
}
