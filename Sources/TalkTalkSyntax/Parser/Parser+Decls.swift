//
//  Parser+Decls.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public extension Parser {
	mutating func varDecl() -> Decl {
		let token = previous!
		let i = startLocation(at: previous)

		guard let name = consume(.identifier, "expected identifier after var")?.lexeme else {
			return SyntaxError(location: endLocation(i), message: "expected identifier after var", expectation: .identifier)
		}

		consume(.colon, "expected ':' after name")

		guard let typeDecl = consume(.identifier) else {
			return SyntaxError(location: endLocation(i), message: "expected identifier after var", expectation: .type)
		}

		return VarDeclSyntax(token: token, name: name, typeDecl: typeDecl.lexeme, typeDeclToken: typeDecl, location: endLocation(i))
	}

	mutating func letVarDecl(_ kind: Token.Kind) -> Decl {
		let token = previous!

		let i = startLocation(at: previous)

		guard let nameToken = consume(.identifier, "expected identifier after var") else {
			return SyntaxError(location: endLocation(i), message: "expected identifier after var", expectation: .identifier)
		}

		let name = nameToken.lexeme

		consume(.colon, "expected ':' after name")

		guard let typeDecl = consume(.identifier)?.lexeme else {
			return SyntaxError(location: endLocation(i), message: "expected identifier after var", expectation: .type)
		}

		if kind == .let {
			return LetDeclSyntax(token: token, name: name, typeDecl: typeDecl, typeDeclToken: nameToken, location: endLocation(i))
		} else {
			return VarDeclSyntax(token: token, name: name, typeDecl: typeDecl, typeDeclToken: nameToken, location: endLocation(i))
		}
	}

	mutating func declBlock() -> DeclBlockExprSyntax {
		consume(.leftBrace, "expected '{' before block")
		skip(.newline)

		let i = startLocation(at: previous)

		var decls: [any Syntax] = []

		while !check(.eof), !check(.rightBrace) {
			skip(.newline)
			decls.append(decl())
			skip(.newline)
		}

		consume(.rightBrace, "expected '}' after block")
		skip(.newline)

		return DeclBlockExprSyntax(decls: decls, location: endLocation(i))
	}
}
