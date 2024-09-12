//
//  PatternVisitor.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/5/24.
//

import TalkTalkSyntax

public struct Pattern: Equatable, Hashable, CustomStringConvertible {
	public enum Argument: Equatable, Hashable {
		case value(InferenceType), variable(String, InferenceType)
	}

	// What is the overall type of this pattern
	public let type: InferenceType

	// What associated values are in this pattern? So like .foo("bar") would
	// have .base(.string) ("bar") as an associated value.
	public let arguments: [Argument]

	init(type: InferenceType, arguments: [Argument]) {
		self.type = type
		self.arguments = arguments
	}

	public var description: String {
		"\(type), \(arguments)"
	}
}

public enum PatternError: Error, CustomStringConvertible {
	case invalid(String)

	public var description: String {
		switch self {
		case .invalid(let string):
			"Invalid pattern: \(string)"
		}
	}
}

struct PatternVisitor: Visitor {
	let inferenceVisitor: InferenceVisitor

	typealias Context = InferenceContext
	typealias Value = Pattern

	// Call expr is used for a lot of this stuff because it gives us basically the
	// syntax we want for enums (parens) and means our parser can stay relatively dumb.
	func visit(_ expr: CallExprSyntax, _ context: InferenceContext) throws -> Pattern {
		guard let matchContext = context.matchContext else {
			throw InferencerError.parametersNotAvailable("Could not get match context for \(expr.description)")
		}

		let isInCaseStatement = matchContext.current is CaseStmtSyntax

		// Make sure the callee is inferred
		try expr.callee.accept(inferenceVisitor, context)

		// Get the callee type
		let type = try context.get(expr.callee).asType(in: context)

		// Get the parameters expected for the callee. For enum cases, this will be the attached types.
		let params: [InferenceType] = try inferenceVisitor.parameters(of: type, in: context, with: isInCaseStatement ? matchContext.substitutions : nil)

		// Pattern arguments in case statements can be either values or variables. If they're variables, we need to bind those
		// to the values in the match target expression.
		var arguments: [Pattern.Argument] = []
		var argumentsSyntax: [any Syntax] = []

		for (i, arg) in expr.args.enumerated() {
			let param = params.indices.contains(i) ? params[i] : nil

			argumentsSyntax.append(arg)

			switch arg.value {
			case let arg as VarLetDecl:
				let typeVar = context.freshTypeVariable(arg.name)

				if let param {
					context.addConstraint(.equality(.typeVar(typeVar), param, at: arg.location))
				}

				context.defineVariable(named: arg.name, as: .typeVar(typeVar), at: arg.location)
				arguments.append(.variable(arg.name, .typeVar(typeVar)))
			case let arg as CallExprSyntax:
				var context = context

				if let param {
					context = context.expecting(param)
				}

				try arg.accept(inferenceVisitor, context)
				
				let pattern = try visit(arg, context)
				arguments.append(.value(.pattern(pattern)))
			case let arg as MemberExprSyntax:
				let pattern = try visit(arg, context)
				arguments.append(.value(.pattern(pattern)))
			case let arg as any Expr:
				try arg.accept(inferenceVisitor, context)
				let type = try context.get(arg).asType(in: context)

				arguments.append(.value(type))

				if isInCaseStatement, let param {
					// If we have a normal expr value and are in a case statement, we want to unify the argument
					// and param.
					context.addConstraint(.equality(type, param, at: arg.location))
				} else if case let .typeVar(typeVariable) = param {
					// If we're not in a case statement but the param is a type variable, we store it in the match
					// context so that cases can refer to it.
					context.matchContext?.substitutions[typeVariable] = type
				}
			default:
				throw PatternError.invalid("Invalid pattern: \(arg)")
			}
		}

		return Pattern(
			type: type,
			arguments: arguments
		)
	}

	func visit(_ expr: Argument, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: LiteralExprSyntax, _ context: InferenceContext) throws -> Pattern {
		try inferenceVisitor.visit(expr, context)
		return try Pattern(
			type: context.get(expr).asType(in: context),
			arguments: []
		)
	}

	func visit(_ expr: VarExprSyntax, _ context: InferenceContext) throws -> Pattern {
		return try Pattern(
			type: context.get(expr).asType(in: context),
			arguments: []
		)
	}

	func visit(_ expr: BinaryExprSyntax, _ context: InferenceContext) throws -> Pattern {
		return try Pattern(
			type: context.get(expr).asType(in: context),
			arguments: []
		)
	}

	func visit(_ expr: StructExprSyntax, _ context: InferenceContext) throws -> Pattern {
		return try Pattern(
			type: context.get(expr).asType(in: context),
			arguments: []
		)
	}

	func visit(_ expr: VarDeclSyntax, _ context: InferenceContext) throws -> Pattern {
		return try Pattern(
			type: context.get(expr).asType(in: context),
			arguments: []
		)
	}

	func visit(_ expr: LetDeclSyntax, _ context: InferenceContext) throws -> Pattern {
		return try Pattern(
			type: context.get(expr).asType(in: context),
			arguments: []
		)
	}

	func visit(_ expr: MemberExprSyntax, _ context: InferenceContext) throws -> Pattern {
		return try Pattern(
			type: context.get(expr).asType(in: context),
			arguments: []
		)
	}

	func visit(_ expr: TypeExprSyntax, _ context: InferenceContext) throws -> Pattern {
		return try Pattern(
			type: context.get(expr).asType(in: context),
			arguments: []
		)
	}

	func visit(_ expr: ArrayLiteralExprSyntax, _ context: InferenceContext) throws -> Pattern {
		return try Pattern(
			type: context.get(expr).asType(in: context),
			arguments: []
		)
	}

	func visit(_ expr: SubscriptExprSyntax, _ context: InferenceContext) throws -> Pattern {
		return try Pattern(
			type: context.get(expr).asType(in: context),
			arguments: []
		)
	}

	func visit(_ expr: DictionaryLiteralExprSyntax, _ context: InferenceContext) throws -> Pattern {
		return try Pattern(
			type: context.get(expr).asType(in: context),
			arguments: []
		)
	}

	func visit(_ expr: DictionaryElementExprSyntax, _ context: InferenceContext) throws -> Pattern {
		return try Pattern(
			type: context.get(expr).asType(in: context),
			arguments: []
		)
	}

	func visit(_ expr: DefExprSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: IdentifierExprSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: UnaryExprSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: IfExprSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: WhileStmtSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: BlockStmtSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: FuncExprSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ParamsExprSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ParamSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: GenericParamsSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: DeclBlockSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ParseErrorSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ReturnStmtSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: InitDeclSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ImportStmtSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ExprStmtSyntax, _ context: InferenceContext) throws -> Pattern {
		try expr.expr.accept(self, context)
	}

	func visit(_ expr: IfStmtSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: StructDeclSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ProtocolDeclSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ProtocolBodyDeclSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: FuncSignatureDeclSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: EnumDeclSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: EnumCaseDeclSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: MatchStatementSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: CaseStmtSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: EnumMemberExprSyntax, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}
}
