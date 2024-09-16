//
//  ProtocolTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/16/24.
//

import Testing

struct ProtocolTests: VMTest {
	@Test("Methods") func methods() throws {
		let result = try run(
		"""
		protocol Greetable { func name() -> String }

		struct Person: Greetable {
			func name() -> String {
				"pat"
			}
		}

		func greet(greetable: Greetable) {
			"hi, " + greetable.name()
		}

		return greet(greetable: Person())
		"""
		)

		#expect(result == .string("hi, pat"))
	}
}
