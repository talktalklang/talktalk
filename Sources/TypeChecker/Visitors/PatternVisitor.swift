//
//  PatternVisitor.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/5/24.
//

import TalkTalkSyntax

public struct Pattern: Equatable, Hashable, CustomStringConvertible {
	public let type: InferenceType
	public let values: [InferenceType]

	public var description: String {
		"\(type), \(values)"
	}
}

public enum PatternError: Error {
	case invalid(String)
}

struct PatternVisitor: Visitor {
	let inferenceVisitor: InferenceVisitor

	typealias Context = InferenceContext
	typealias Value = Pattern

	func visit(_ expr: CallExprSyntax, _ context: InferenceContext) throws -> Pattern {
		try expr.callee.accept(inferenceVisitor, context)

		let params: [InferenceType] = if let expectation = context.expectation {
			try inferenceVisitor.parameters(of: expectation)
		} else {
			[]
		}

		var values: [InferenceType] = []
		for (arg, param) in zip(expr.args, params) {
			switch arg.value {
			case let arg as VarDecl:
				let typeVar = context.freshTypeVariable(arg.name)
				context.addConstraint(.equality(.typeVar(typeVar), param, at: arg.location))
				context.defineVariable(named: arg.name, as: .typeVar(typeVar), at: arg.location)
				values.append(.typeVar(typeVar))
			case let arg as LetDecl:
				let typeVar = context.freshTypeVariable(arg.name)
				context.addConstraint(.equality(.typeVar(typeVar), param, at: arg.location))
				context.defineVariable(named: arg.name, as: .typeVar(typeVar), at: arg.location)
				values.append(.typeVar(typeVar))
			case let arg as any Expr:
				try arg.accept(inferenceVisitor, context)
				try values.append(context.get(arg).asType(in: context))
			default:
				throw PatternError.invalid("Invalid pattern: \(arg)")
			}
		}

		return try Pattern(type: context.expectation ?? context.get(expr.callee).asType(in: context), values: values)
	}

	func visit(_ expr: Argument, _ context: InferenceContext) throws -> Pattern {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: LiteralExprSyntax, _ context: InferenceContext) throws -> Pattern {
		try inferenceVisitor.visit(expr, context)
		return try Pattern(type: context.get(expr).asType(in: context), values: [])
	}

	func visit(_ expr: VarExprSyntax, _ context: InferenceContext) throws -> Pattern {
		Pattern(type: .any, values: [])
	}

	func visit(_ expr: BinaryExprSyntax, _ context: InferenceContext) throws -> Pattern {
		Pattern(type: .any, values: [])
	}

	func visit(_ expr: StructExprSyntax, _ context: InferenceContext) throws -> Pattern {
		Pattern(type: .any, values: [])
	}

	func visit(_ expr: VarDeclSyntax, _ context: InferenceContext) throws -> Pattern {
		Pattern(type: .any, values: [])
	}

	func visit(_ expr: LetDeclSyntax, _ context: InferenceContext) throws -> Pattern {
		Pattern(type: .any, values: [])
	}

	func visit(_ expr: MemberExprSyntax, _ context: InferenceContext) throws -> Pattern {
		Pattern(type: .any, values: [])
	}

	func visit(_ expr: TypeExprSyntax, _ context: InferenceContext) throws -> Pattern {
		Pattern(type: .any, values: [])
	}

	func visit(_ expr: ArrayLiteralExprSyntax, _ context: InferenceContext) throws -> Pattern {
		Pattern(type: .any, values: [])
	}

	func visit(_ expr: SubscriptExprSyntax, _ context: InferenceContext) throws -> Pattern {
		Pattern(type: .any, values: [])
	}

	func visit(_ expr: DictionaryLiteralExprSyntax, _ context: InferenceContext) throws -> Pattern {
		Pattern(type: .any, values: [])
	}

	func visit(_ expr: DictionaryElementExprSyntax, _ context: InferenceContext) throws -> Pattern {
		Pattern(type: .any, values: [])
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