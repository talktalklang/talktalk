//
//  Parser+Decls.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public extension Parser {
	mutating func letVarDecl(_ kind: Token.Kind) -> any Stmt {
		let token = previous!

		let i = startLocation(at: previous)

		guard let nameToken = consume(.identifier, "expected identifier after var") else {
			return error(at: current, .unexpectedToken(expected: .identifier, got: current), expectation: .identifier)
		}

		var typeExpr: (any TypeExpr)? = nil
		if didMatch(.colon) {
			typeExpr = self.typeExpr()
		}

		var value: (any Expr)?
		if didMatch(.equals) {
			value = parse(precedence: .assignment)
		}

		if kind == .let {
			return LetDeclSyntax(
				id: nextID(),
				token: token,
				name: nameToken.lexeme,
				nameToken: nameToken,
				typeExpr: typeExpr,
				value: value,
				location: endLocation(i)
			)
		} else {
			return VarDeclSyntax(
				id: nextID(),
				token: token,
				name: nameToken.lexeme,
				nameToken: nameToken,
				typeExpr: typeExpr,
				value: value,
				location: endLocation(i)
			)
		}
	}

	mutating func _init() -> Decl {
		let i = startLocation(at: previous!)
		let initToken = previous!
		skip(.newline)
		consume(.leftParen, "expected '(' before params")

		// Parse parameter list
		skip(.newline)
		let params = parameterList()
		skip(.newline)

		let body = blockStmt(false)
		return InitDeclSyntax(
			id: nextID(),
			initToken: initToken,
			params: params,
			body: body,
			location: endLocation(i)
		)
	}

	mutating func declBlock() -> DeclBlockSyntax {
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

		return DeclBlockSyntax(id: nextID(), decls: decls, location: endLocation(i))
	}

	mutating func structDecl() -> any Syntax {
		let structToken = previous!
		let i = startLocation(at: previous)

		guard let name = consume(.identifier) else {
			return error(
				at: current,
				.unexpectedToken(expected: .identifier, got: current),
				expectation: .structName
			)
		}

		var genericParamsSyntax: GenericParamsSyntax?
		if didMatch(.less) {
			genericParamsSyntax = genericParams()
		}

		let body = declBlock()

		return StructDeclSyntax(
			id: nextID(), 
			structToken: structToken,
			name: name.lexeme,
			nameToken: name,
			body: body,
			genericParams: genericParamsSyntax,
			location: endLocation(i)
		)
	}
}
