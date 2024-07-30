//
//  Parser+Decls.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public extension Parser {
	mutating func varDecl() -> Decl {
		startLocation(at: previous)

		guard let name = consume(.identifier, "expected identifier after var")?.lexeme else {
			return SyntaxError(location: endLocation(), message: "expected identifier after var")
		}

		consume(.colon, "expected ':' after name")

		guard let typeDecl = consume(.identifier)?.lexeme else {
			return SyntaxError(location: endLocation(), message: "expected identifier after var")
		}

		return VarDeclSyntax(name: name, typeDecl: typeDecl, location: endLocation())
	}

	mutating func letVarDecl(_ kind: Token.Kind) -> Decl {
		startLocation(at: previous)

		guard let name = consume(.identifier, "expected identifier after var")?.lexeme else {
			return SyntaxError(location: endLocation(), message: "expected identifier after var")
		}

		consume(.colon, "expected ':' after name")

		guard let typeDecl = consume(.identifier)?.lexeme else {
			return SyntaxError(location: endLocation(), message: "expected identifier after var")
		}

		if kind == .let {
			return LetDeclSyntax(name: name, typeDecl: typeDecl, location: endLocation())
		} else {
			return VarDeclSyntax(name: name, typeDecl: typeDecl, location: endLocation())
		}
	}

	mutating func declBlock() -> DeclBlockExprSyntax {
		consume(.leftBrace, "expected '{' before block")
		skip(.newline)

		startLocation(at: previous)

		var decls: [any Decl] = []

		while !check(.eof), !check(.rightBrace) {
			skip(.newline)
			decls.append(decl())
			skip(.newline)
		}

		consume(.rightBrace, "expected '}' after block")
		skip(.newline)

		return DeclBlockExprSyntax(decls: decls, location: endLocation())
	}
}
