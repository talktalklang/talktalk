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
			[.enum, .struct, .protocol, .func, .initialize, .var, .let, .static]
		case .enum:
			[.enum, .struct, .protocol, .func, .case, .static]
		case .topLevel:
			[.enum, .struct, .protocol, .func, .var, .let]
		case .argument:
			[.var, .func, .let]
		}
	}

	var isLexicalScopeBody: Bool {
		[.enum, .struct].contains(self)
	}
}

public extension Parser {
	mutating func enumDecl() -> any Decl {
		let token = previous.unsafelyUnwrapped
		let i = startLocation(at: token)
		guard let nameToken = consume(.identifier) else {
			return error(
				at: current, .unexpectedToken(expected: .identifier, got: current),
				expectation: .none
			)
		}

		var typeParams: [TypeExprSyntax] = []
		if didMatch(.less) {
			// We've got a generic param list
			typeParams = typeParameters()
		}

		var conformances: [TypeExprSyntax] = []
		if didMatch(.colon) {
			repeat {
				conformances.append(typeExpr().cast(TypeExprSyntax.self))
			} while didMatch(.comma)
		}

		let body = declBlock(context: .enum)

		return EnumDeclSyntax(
			enumToken: token,
			nameToken: nameToken,
			conformances: conformances,
			body: body,
			typeParams: typeParams,
			id: nextID(),
			location: endLocation(i)
		)
	}

	mutating func enumCaseDecl() -> any Decl {
		let token = previous.unsafelyUnwrapped
		let i = startLocation(at: token)

		guard let nameToken = consume(.identifier) else {
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

	mutating func methodDecl(isStatic: Bool, modifiers: [Token] = []) -> any Decl {
		let funcToken = previous.unsafelyUnwrapped
		let i = startLocation(at: previous)

		skip(.newline)

		// Grab the name if there is one
		guard let name = consume(.identifier) else {
			return error(at: current, expected(.identifier))
		}

		skip(.newline)
		consume(.leftParen)
		skip(.newline)

		// Parse parameter list
		let params = parameterList()

		skip(.newline)

		let typeAnnotation: TypeExprSyntax? = if didMatch(.forwardArrow) {
			typeExpr()
		} else {
			nil
		}

		let body = blockStmt(false)

		return MethodDeclSyntax(
			funcToken: funcToken,
			modifiers: modifiers,
			nameToken: name,
			params: params,
			returns: typeAnnotation,
			body: body,
			isStatic: isStatic,
			id: nextID(),
			location: endLocation(i)
		)
	}

	mutating func letVarDecl(_ kind: Token.Kind, isStatic: Bool, modifiers: [Token] = []) -> any Decl {
		let token = previous.unsafelyUnwrapped

		let i = startLocation(at: previous)

		guard let nameToken = consume(.identifier) else {
			return error(at: current, .unexpectedToken(expected: .identifier, got: current), expectation: .identifier)
		}

		var typeExpr: TypeExprSyntax?
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
				isStatic: isStatic,
				modifiers: modifiers,
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
				isStatic: isStatic,
				modifiers: modifiers,
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
		consume(.leftParen)

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

	mutating func propertyDecl(_ keyword: Token, isStatic: Bool, modifiers: [Token]) -> any Decl {
		let keyword = previous!
		let i = startLocation(at: keyword)

		guard let name = consume(.identifier) else {
			return error(at: current, expected(.identifier))
		}

		let typeAnnotation: TypeExprSyntax?
		if didMatch(.colon) {
			typeAnnotation = typeExpr()
		} else {
			typeAnnotation = nil
		}

		let defaultValue: (any Expr)?
		if didMatch(.equals) {
			defaultValue = expr()
		} else {
			defaultValue = nil
		}

		return PropertyDeclSyntax(
			introducer: keyword,
			name: name,
			typeAnnotation: typeAnnotation,
			defaultValue: defaultValue,
			isStatic: isStatic,
			id: nextID(),
			location: endLocation(i)
		)
	}

	mutating func declBlock(context: DeclContext) -> DeclBlockSyntax {
		consume(.leftBrace)
		skip(.newline)

		let i = startLocation(at: previous)

		var decls: [any Syntax] = []

		while !check(.eof), !check(.rightBrace) {
			skip(.newline)
			decls.append(decl(context: context))
			skip(.newline)
		}

		consume(.rightBrace)
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
		consume(.leftBrace)
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
				decls.append(letVarDecl(.var, isStatic: false))
				skip(.newline)
			}

			if didMatch(.let) {
				decls.append(letVarDecl(.let, isStatic: false))
			}

			skip(.newline)
		}

		consume(.rightBrace)
		skip(.newline)

		return ProtocolBodyDeclSyntax(decls: decls, id: nextID(), location: endLocation(i))
	}
}
