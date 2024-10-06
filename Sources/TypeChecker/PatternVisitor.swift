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
			try zip(syntax.args, parameters).map { (arg, param) in
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

	func visit(_ syntax: DefExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: IdentifierExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: LiteralExprSyntax, _ context: Context) throws -> Pattern {
		let type = try visitor.visit(syntax, context).instantiate(in: context).type
		return .value(type)
	}

	func visit(_ syntax: VarExprSyntax, _ context: Context) throws -> Pattern {
		return .variable(syntax.name, context.expectedType ?? .resolved(.typeVar(context.freshTypeVariable(syntax.name))))
	}

	func visit(_ syntax: UnaryExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: BinaryExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: IfExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: WhileStmtSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: BlockStmtSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: FuncExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: ParamsExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: ParamSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: GenericParamsSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: Argument, _ context: Context) throws -> Pattern {
		try syntax.value.accept(self, context)
	}

	func visit(_ syntax: StructExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: DeclBlockSyntax, _ context: Context) throws -> Pattern {
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

	func visit(_ syntax: ParseErrorSyntax, _ context: Context) throws -> Pattern {
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

	func visit(_ syntax: ReturnStmtSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: InitDeclSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: ImportStmtSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: TypeExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: ExprStmtSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: IfStmtSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: StructDeclSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: ArrayLiteralExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: SubscriptExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: DictionaryLiteralExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: DictionaryElementExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: ProtocolDeclSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: ProtocolBodyDeclSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: FuncSignatureDeclSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: EnumDeclSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: EnumCaseDeclSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: MatchStatementSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: CaseStmtSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: EnumMemberExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: InterpolatedStringExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: ForStmtSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: LogicalExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: GroupedExprSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: LetPatternSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: PropertyDeclSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}

	func visit(_ syntax: MethodDeclSyntax, _ context: Context) throws -> Pattern {
		fatalError("TODO")
	}
}
