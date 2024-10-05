//
//  ProtocolTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//

import TalkTalkCore
import Testing
@testable import TypeChecker

struct ProtocolTests: TypeCheckerTest {
	@Test("Types protocol decl") func protocolType() throws {
		let syntax = try Parser.parse(
			"""
			protocol Greetable {
				var name: String

				func greet() -> String
			}
			"""
		)

		let context = try solve(syntax)

		let protocolType = ProtocolType.extract(from: context[syntax[0]]!)!
		#expect(protocolType.name == "Greetable")
		#expect(protocolType.member(named: "name") == .resolved(.base(.string)))
		#expect(protocolType.member(named: "greet") == .resolved(.function([], .resolved(.base(.string)))))
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

		let context = try solve(syntax)

		let protocolType = ProtocolType.extract(from: context[syntax[0]]!)!
		let fn = context.find(syntax[1])!

		#expect(fn == .function(
			[
			.resolved(.instance(.protocol(Instance(type: protocolType, substitutions: [:])))),
			],
			.resolved(.base(.string))
		))
	}

	@Test("Infers params from protocol") func inferParam() throws {
		let syntax = try Parser.parse(
			#"""
			protocol Greetable {
				func greet(name: String) -> String
			}

			struct Person: Greetable {
				func greet(name) {
					"hi, " + name
				}
			}
			"""#
		)

		let context = try solve(syntax)

		let structType = StructType.extract(from: context.find(syntax[1])!)!
		let greetMethod = structType.member(named: "greet")!

		guard case let .function(params, returns) = context.applySubstitutions(to: greetMethod) else {
			#expect(Bool(false), "did not get greet function")
			return
		}

		#expect(returns == .resolved(.base(.string)))
		#expect(context.applySubstitutions(to: params[0]) == .base(.string))
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

		let context = try solve(syntax)

		let protocolType = ProtocolType.extract(from: context.find(syntax[0])!)!
		let fn = context.find(syntax[1])!

		#expect(fn == .function([
			.resolved(.instance(.protocol(Instance(type: protocolType)))),
		], .resolved(.base(.string))))
	}
}
