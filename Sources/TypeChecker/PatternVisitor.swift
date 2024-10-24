//
//  PatternVisitor.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/3/24.
//

import TalkTalkCore

struct PatternVisitor: Visitor {
	typealias Context = TypeChecker.Context
	typealias Value = Pattern

	let visitor: ContextVisitor

	// MARK: Visits

	func visit(_ syntax: CallExprSyntax, _ context: Context) throws -> Pattern {
		guard let expectedType = context.expectedType else {
			throw TypeError.typeError("No target found for pattern: \(syntax.description)")
		}

		let callee = try syntax.callee.accept(visitor, context)
		let args = if let parameters = visitor.parameters(for: callee) {
			try zip(syntax.args, parameters).map { arg, param in
				try context.expecting(param) {
					try arg.accept(self, context)
				}
			}
		} else {
			try syntax.args.map { try $0.value.accept(self, context) }
		}

		context.addConstraint(
			Constraints.Bind(
				context: context,
				target: expectedType,
				pattern: .call(callee, args),
				location: syntax.location
			)
		)

		context.define(syntax, as: .resolved(.pattern(.call(callee, args))))

		return .call(callee, args)
	}

	func visit(_: DefExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: IdentifierExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: LiteralExprSyntax, _ context: Context) throws -> Pattern {
		let type = try visitor.visit(syntax, context).instantiate(in: context).type
		return .value(type)
	}

	func visit(_ syntax: VarExprSyntax, _ context: Context) throws -> Pattern {
		.variable(syntax.name, context.expectedType ?? .resolved(.typeVar(context.freshTypeVariable(syntax.name))))
	}

	func visit(_: UnaryExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: BinaryExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: IfExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: WhileStmtSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: BlockStmtSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: FuncExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: ParamsExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: ParamSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: GenericParamsSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: Argument, _ context: Context) throws -> Pattern {
		try syntax.value.accept(self, context)
	}

	func visit(_: StructExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: DeclBlockSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: VarDeclSyntax, _ context: Context) throws -> Pattern {
		let typeVar = context.freshTypeVariable(syntax.name)
		context.define(syntax.name, as: .resolved(.typeVar(typeVar)))
		context.define(syntax, as: .resolved(.typeVar(typeVar)))
		return .variable(syntax.name, .resolved(.typeVar(typeVar)))
	}

	func visit(_ syntax: LetDeclSyntax, _ context: Context) throws -> Pattern {
		let typeVar = context.freshTypeVariable(syntax.name)
		context.define(syntax.name, as: .resolved(.typeVar(typeVar)))
		context.define(syntax, as: .resolved(.typeVar(typeVar)))
		return .variable(syntax.name, .resolved(.typeVar(typeVar)))
	}

	func visit(_: ParseErrorSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: MemberExprSyntax, _ context: Context) throws -> Pattern {
		let receiver = try syntax.receiver?.accept(visitor, context)

		guard let expectedType = context.expectedType else {
			throw TypeError.typeError("Could not determine receiver: \(syntax.description)")
		}

		if let member = visitor.member(from: receiver ?? expectedType, named: syntax.property) {
			// FIXME: Bad. We don't want to instantiate in the visitor
			context.define(syntax, as: .resolved(.pattern(.value(member.instantiate(in: context).type))))
			return .value(member.instantiate(in: context).type)
		} else {
			let memberTypeVar = context.freshTypeVariable("\(receiver?.description ?? "").\(syntax.property)")
			context.define(syntax, as: .resolved(.pattern(.value(.typeVar(memberTypeVar)))))
			return .value(.typeVar(memberTypeVar))
		}

		return .value(.void)
	}

	func visit(_: ReturnStmtSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: InitDeclSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: ImportStmtSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: TypeExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: ExprStmtSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: IfStmtSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: StructDeclSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: ArrayLiteralExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: SubscriptExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: DictionaryLiteralExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: DictionaryElementExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: ProtocolDeclSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: ProtocolBodyDeclSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: FuncSignatureDeclSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: EnumDeclSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: EnumCaseDeclSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: MatchStatementSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: CaseStmtSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: EnumMemberExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: InterpolatedStringExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: ForStmtSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: LogicalExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: GroupedExprSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: LetPatternSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: PropertyDeclSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_: MethodDeclSyntax, _: Context) throws -> Pattern {
		fatalError("TODO")
	}
}
