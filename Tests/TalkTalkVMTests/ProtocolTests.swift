//
//  ProtocolTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/16/24.
//

import Testing

struct ProtocolTests: VMTest {
	@Test("Properties on structs") func propertiesStruct() throws {
		let result = try run(
			"""
			protocol Greetable { var name: String }

			struct Person: Greetable {
				var name: String
			}

			func greet(greetable: Greetable) {
				"hi, " + greetable.name
			}

			return greet(greetable: Person(name: "pat"))
			"""
		)

		#expect(result == .string("hi, pat"))
	}

	@Test("Methods on structs") func methodsOnStructs() throws {
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

	@Test("Methods on enums") func methodsOnEnums() throws {
		let result = try run(
			"""
			protocol Greetable { func name() -> String }

			enum Person: Greetable {
				case main

				func name() -> String {
					"pat"
				}
			}

			func greet(greetable: Greetable) {
				"hi, " + greetable.name()
			}

			return greet(greetable: Person.main)
			"""
		)

		#expect(result == .string("hi, pat"))
	}
}