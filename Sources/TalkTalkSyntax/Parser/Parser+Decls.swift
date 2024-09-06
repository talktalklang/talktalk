//
//  Parser+Decls.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public enum DeclContext {
	case `struct`, `enum`, topLevel, argument

	var allowed: Set<Token.Kind> {
		switch self {
		case .struct:
			[.enum, .struct, .protocol, .func, .initialize, .var, .let]
		case .enum:
			[.enum, .struct, .protocol, .func, .case]
		case .topLevel:
			[.enum, .struct, .protocol, .func, .var, .let]
		case .argument:
			[.var, .let]
		}
	}
}

public extension Parser {
	mutating func enumDecl() -> any Decl {
		let token = previous.unsafelyUnwrapped
		let i = startLocation(at: token)
		guard let nameToken = consume(.identifier, "expected enum name") else {
			return error(
				at: current, .unexpectedToken(expected: .identifier, got: current),
				expectation: .none
			)
		}

		let body = declBlock(context: .enum)

		return EnumDeclSyntax(
			enumToken: token,
			nameToken: nameToken,
			body: body,
			id: nextID(),
			location: endLocation(i)
		)
	}

	mutating func enumCaseDecl() -> any Decl {
		let token = previous.unsafelyUnwrapped
		let i = startLocation(at: token)

		guard let nameToken = consume(.identifier, "expected enum case name") else {
			return error(
				at: current, .unexpectedToken(expected: .identifier, got: current),
				expectation: .none
			)
		}

		var typeExprs: [TypeExprSyntax] = []
		if didMatch(.leftParen) {
			repeat {
				typeExprs.append(typeExpr())
			} while didMatch(.comma)

			consume(.rightParen)
		}

		return EnumCaseDeclSyntax(
			caseToken: token,
			nameToken: nameToken,
			attachedTypes: typeExprs,
			id: nextID(),
			location: endLocation(i)
		)
	}

	mutating func letVarDecl(_ kind: Token.Kind) -> any Decl {
		let token = previous.unsafelyUnwrapped

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
		let i = startLocation(at: previous.unsafelyUnwrapped)
		let initToken = previous.unsafelyUnwrapped
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

	mutating func declBlock(context: DeclContext) -> DeclBlockSyntax {
		consume(.leftBrace, "expected '{' before block")
		skip(.newline)

		let i = startLocation(at: previous)

		var decls: [any Syntax] = []

		while !check(.eof), !check(.rightBrace) {
			skip(.newline)
			decls.append(decl(context: context))
			skip(.newline)
		}

		consume(.rightBrace, "expected '}' after block")
		skip(.newline)

		return DeclBlockSyntax(id: nextID(), decls: decls, location: endLocation(i))
	}

	mutating func structDecl() -> any Syntax {
		let structToken = previous.unsafelyUnwrapped
		let i = startLocation(at: previous)

		guard let name = consume(.identifier) else {
			return error(
				at: current,
				.unexpectedToken(expected: .identifier, got: current),
				expectation: .structName
			)
		}

		var typeParameters: [TypeExprSyntax] = []
		if didMatch(.less) {
			typeParameters = self.typeParameters()
		}

		var conformances: [TypeExprSyntax] = []
		if didMatch(.colon) {
			repeat {
				conformances.append(typeExpr().cast(TypeExprSyntax.self))
			} while didMatch(.comma)
		}

		let body = declBlock(context: .struct)

		return StructDeclSyntax(
			id: nextID(), 
			structToken: structToken,
			name: name.lexeme,
			nameToken: name,
			body: body,
			typeParameters: typeParameters,
			conformances: conformances,
			location: endLocation(i)
		)
	}

	mutating func protocolDecl() -> any Syntax {
		let protocolToken = previous.unsafelyUnwrapped
		let i = startLocation(at: protocolToken)

		guard let name = consume(.identifier) else {
			return error(
				at: current,
				.unexpectedToken(expected: .identifier, got: current),
				expectation: .none
			)
		}

		var typeParameters: [TypeExprSyntax] = []
		if didMatch(.less) {
			typeParameters = self.typeParameters()
		}

		let body = protocolDeclBlock()

		return ProtocolDeclSyntax(
			id: nextID(),
			keywordToken: protocolToken,
			name: name,
			body: body,
			typeParameters: typeParameters,
			location: endLocation(i)
		)
	}

	mutating func protocolDeclBlock() -> ProtocolBodyDeclSyntax {
		consume(.leftBrace, "expected '{' before block")
		skip(.newline)

		let i = startLocation(at: previous)

		var decls: [any Decl] = []

		while !check(.eof), !check(.rightBrace) {
			skip(.newline)
			if didMatch(.func) {
				decls.append(funcSignatureDecl())
				skip(.newline)
				if check(.leftBrace) {
					_ = error(at: current, .syntaxError("func decls in protocol bodies cannot have bodies"), expectation: .none)
				}

				skip(.newline)
			}

			if didMatch(.initialize) {
				decls.append(_init())
				skip(.newline)
			}

			if didMatch(.var) {
				decls.append(letVarDecl(.var))
				skip(.newline)
			}

			if didMatch(.let) {
				decls.append(letVarDecl(.let))
			}

			skip(.newline)
		}

		consume(.rightBrace, "expected '}' after block")
		skip(.newline)

		return ProtocolBodyDeclSyntax(decls: decls, id: nextID(), location: endLocation(i))
	}
}
