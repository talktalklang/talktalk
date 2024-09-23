//
//  ProtocolTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/15/24.
//

import TalkTalkBytecode
import Testing

struct ProtocolTests: CompilerTest {
	@Test("Can compile a protocol property") func protocolProperty() throws {
		let module = try compile(
			#"""
			protocol Greetable {
				var name: String
			}

			struct Person: Greetable {
				var name: String
			}

			func greet(greetable: Greetable) -> String {
				"hi " + greetable.name
			}

			greet(Person("pat"))
			"""#
		)

		let main = module.chunks[.function(module.name, "0.talk", [])]!
		try #expect(main.disassemble(in: module) == Instructions(
			.op(.defClosure, line: 8, .closure(name: "greet", arity: 1, depth: 0)),
			.op(.data, line: 12, .data(.init(kind: .string, bytes: [Byte]("pat".utf8)))),
			.op(.getStruct, line: 12, .struct(.struct("E2E", "Person"))),
			.op(.call, line: 12),
			.op(.getModuleFunction, line: 12, .moduleFunction(.function("E2E", "greet", ["IGreetable"]))),
			.op(.call, line: 12),
			.op(.pop, line: 12),
			.op(.returnVoid, line: 0)
		))

		let fn = try #require(module.chunks[.function("E2E", "greet", ["IGreetable"])])
		try #expect(fn.disassemble(in: module) == Instructions(
			.op(.getLocal, line: 9, .local(.value("E2E", "greetable"))),
			.op(.getProperty, line: 9, .getProperty(.property("E2E", nil, "name"), options: [])),
			.op(.data, line: 9, .data(.init(kind: .string, bytes: [Byte]("hi ".utf8)))),
			.op(.add, line: 9),
			.op(.returnValue, line: 9),
			.op(.returnValue, line: 10)
		))
	}

	@Test("Can compile a protocol method") func protocolMethod() throws {
		let module = try compile(
			#"""
			protocol Greetable {
				func name() -> String
			}

			struct Person: Greetable {
				func name() -> String {
					"pat"
				}
			}

			func greet(greetable: Greetable) -> String {
				"hi " + greetable.name()
			}

			greet(Person())
			"""#
		)

		let main = module.chunks[.function(module.name, "0.talk", [])]!
		try #expect(main.disassemble(in: module) == Instructions(
			.op(.defClosure, line: 10, .closure(name: "greet", arity: 1, depth: 0)),
			.op(.getStruct, line: 14, .struct(.struct("E2E", "Person"))),
			.op(.call, line: 14),
			.op(.getModuleFunction, line: 14, .moduleFunction(.function("E2E", "greet", ["IGreetable"]))),
			.op(.call, line: 14),
			.op(.pop, line: 14),
			.op(.returnVoid, line: 0)
		))

		let fn = try #require(module.chunks[.function("E2E", "greet", ["IGreetable"])])
		try #expect(fn.disassemble(in: module) == Instructions(
			.op(.getLocal, line: 11, .local(.value("E2E", "greetable"))),
			.op(.getProperty, line: 11, .getProperty(.method("E2E", nil, "name", []), options: .isMethod)),
			.op(.call, line: 11),
			.op(.data, line: 11, .data(.init(kind: .string, bytes: [Byte]("hi ".utf8)))),
			.op(.add, line: 11),
			.op(.returnValue, line: 11),
			.op(.returnValue, line: 12)
		))
	}
}
