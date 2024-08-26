//
//  ProtocolTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/26/24.
//

import Testing
import TalkTalkSyntax

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
}
