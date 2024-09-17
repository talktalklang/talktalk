//
//  ProtocolTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//

import TalkTalkSyntax
import Testing

struct ProtocolTests {
	@Test("Can parse a protocol") func basic() throws {
		let parsed = try Parser.parse(
			"""
			protocol Basic {}
			"""
		)

		let protocolDef = try #require(parsed[0] as? ProtocolDeclSyntax)
		#expect(protocolDef.name.lexeme == "Basic")
	}

	@Test("Can parse a func requirement") func funcRequirement() throws {
		let parsed = try Parser.parse(
			"""
			protocol Basic {
				func someMethod(name: String) -> int
			}
			"""
		)

		let protocolDef = try #require(parsed[0] as? ProtocolDeclSyntax)
		#expect(protocolDef.name.lexeme == "Basic")
		#expect(protocolDef.body.decls.count == 1)

		let funcSigDef = try #require(protocolDef.body.decls[0] as? FuncSignatureDeclSyntax)
		#expect(funcSigDef.name.lexeme == "someMethod")
		#expect(funcSigDef.params.params.map(\.name) == ["name"])
		#expect(funcSigDef.params.params.map(\.type?.identifier.lexeme) == ["String"])
		#expect(funcSigDef.returnDecl.identifier.lexeme == "int")
	}

	@Test("Can parse a property requirement") func propertyRequirement() throws {
		let parsed = try Parser.parse(
			"""
			protocol Basic {
				var name: String
			}
			"""
		)

		let protocolDef = try #require(parsed[0] as? ProtocolDeclSyntax)
		#expect(protocolDef.name.lexeme == "Basic")
		#expect(protocolDef.body.decls.count == 1)

		let varDecl = try #require(protocolDef.body.decls[0] as? VarDeclSyntax)
		#expect(varDecl.name == "name")
		#expect(varDecl.typeExpr?.identifier.lexeme == "String")
	}

	@Test("Can parse a conformance") func conformance() throws {
		let parsed = try Parser.parse(
			"""
			struct Fizz: Buzz {}
			"""
		)

		let structDef = try #require(parsed[0] as? StructDeclSyntax)
		#expect(structDef.name == "Fizz")
		#expect(structDef.conformances[0].identifier.lexeme == "Buzz")
	}

	@Test("Can parse a type requirement") func typeRequirement() throws {
		let parsed = try Parser.parse(
			"""
			protocol Basic<Wrapped> {
				var name: Wrapped
			}
			"""
		)

		let protocolDef = try #require(parsed[0] as? ProtocolDeclSyntax)
		#expect(protocolDef.name.lexeme == "Basic")
		#expect(protocolDef.typeParameters.count == 1)
		#expect(protocolDef.typeParameters[0].identifier.lexeme == "Wrapped")
	}
}
