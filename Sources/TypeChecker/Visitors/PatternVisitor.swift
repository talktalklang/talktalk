//
//  PatternVisitor.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/5/24.
//

import Foundation
import TalkTalkCore

public struct Pattern: Equatable, Hashable, CustomStringConvertible {
	public enum Argument: Equatable, Hashable {
		case value(InferenceType), variable(String, InferenceResult)
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

public enum PatternError: Error, CustomStringConvertible, LocalizedError {
	case invalid(String)

	public var errorDescription: String? {
		switch self {
		case let .invalid(string):
			string
		}
	}

	public var description: String {
		switch self {
		case let .invalid(string):
			"Invalid pattern: \(string)"
		}
	}
}

struct PatternVisitor: Visitor {
	let inferenceVisitor: InferenceVisitor

	typealias Context = InferenceContext
	typealias Value = Pattern.Argument

	func unresolvedReceiver(_ expr: MemberExprSyntax, context: InferenceContext) throws -> Pattern.Argument {
		switch context.expectation {
		case let .type(.instance(instance)):
			if let member = instance.member(named: expr.property, in: context) {
				context.extend(expr, with: .type(member))
				return .value(member)
			}
		case let .type(.instantiatable(type)):
			if let member = type.member(named: expr.property, in: context) {
				context.extend(expr, with: member)
				return .value(member.asType(in: context))
			}
		default:
			if let expectation = context.expectation {
				let typeVar = context.freshTypeVariable(".\(expr.property)")
				context.addConstraint(
					MemberConstraint(receiver: expectation, name: expr.property, type: .type(.typeVar(typeVar)), isRetry: false, location: expr.location)
				)

				context.extend(expr, with: .type(.typeVar(typeVar)))

				return .value(.typeVar(typeVar))
			}
		}

		throw InferencerError.cannotInfer("could not resolve receiver of \(expr.description)")
	}

	func visit(_ expr: CallExprSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		guard case let .value(type) = try expr.callee.accept(self, context) else {
			throw PatternError.invalid("variable cannot be callee")
		}

		let params = try inferenceVisitor.parameters(of: context.get(expr.callee).asType(in: context), in: context)

		var args: [Pattern.Argument] = []
		for (param, arg) in zip(params, expr.args) {
			try context.expecting(param.asType(in: context)) {
				try arg.accept(inferenceVisitor, context)
				try args.append(
					arg.value.accept(self, context)
				)
			}

			try context.addConstraint(.equality(context.get(arg), param, at: arg.location))
		}

		try context.addConstraint(ParamsConstraint(callee: context.get(expr.callee), args: expr.args.map {
			if context[$0] == nil {
				try $0.accept(inferenceVisitor, context)
			}

			return try context.get($0)
		}, location: expr.location, isRetry: false))

		return .value(
			InferenceType.pattern(
				Pattern(
					type: type,
					arguments: args
				)
			)
		)

//		// Make sure the callee is inferred
//		try expr.callee.accept(inferenceVisitor, context)
//
//		// Get the callee type
//		let type = try context.get(expr.callee).asType(in: context)
//
//		// Get the parameters expected for the callee. For enum cases, this will be the attached types.
//		let params: [InferenceType] = try inferenceVisitor.parameters(of: type, in: context)
//
//		// Pattern arguments in case statements can be either values or variables. If they're variables, we need to bind those
//		// to the values in the match target expression.
//		var arguments: [Pattern.Argument] = []
//		var argumentsSyntax: [any Syntax] = []
//
//		for (i, arg) in expr.args.enumerated() {
//			let param = params.indices.contains(i) ? params[i] : nil
//
//			argumentsSyntax.append(arg)
//
//			switch arg.value {
//			case let arg as VarLetDecl:
//				let typeVar = context.freshTypeVariable(arg.name)
//
//				if let param {
//					context.addConstraint(.equality(.typeVar(typeVar), param, at: arg.location))
//				}
//
//				context.defineVariable(named: arg.name, as: .typeVar(typeVar), at: arg.location)
//				arguments.append(.variable(arg.name, .typeVar(typeVar)))
//			case let arg as CallExprSyntax:
//				guard let param else {
//					throw InferencerError.cannotInfer("Could not determine expected type for \(arg)")
//				}
//
//				let context = context.expecting(param)
//
//				try arg.accept(inferenceVisitor, context)
//				let pattern = try visit(arg, context)
//
//				arguments.append(.value(.pattern(pattern)))
//			case let arg as MemberExprSyntax:
//				let pattern = try visit(arg, context)
//				arguments.append(.value(.pattern(pattern)))
//			case let arg as any Expr:
//				try arg.accept(inferenceVisitor, context)
//				let type = try context.get(arg).asType(in: context)
//
//				arguments.append(.value(type))
//
//				if let param {
//					// If we have a normal expr value and are in a case statement, we want to unify the argument
//					// and param.
//					context.addConstraint(.equality(type, param, at: arg.location))
//				}
//			default:
//				throw PatternError.invalid("Invalid pattern: \(arg)")
//			}
//		}
//
//		return Pattern(
//			type: type,
//			arguments: arguments
//		)
	}

	func visit(_ expr: Argument, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: LiteralExprSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		try inferenceVisitor.visit(expr, context)
		return try .value(context.get(expr).asType(in: context))
	}

	func visit(_ expr: VarExprSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		let type = try context.expectation ?? context.get(expr)

		context.extend(expr, with: type)

		return .variable(expr.name, type)
	}

	func visit(_ expr: BinaryExprSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		try .value(context.get(expr).asType(in: context))
	}

	func visit(_ expr: StructExprSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		try .value(context.get(expr).asType(in: context))
	}

	func visit(_ expr: VarDeclSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
//		try context.defineVariable(named: expr.name, as: context.get(expr).asType(in: context), at: expr.location)

		try .variable(expr.name, context.get(expr))
	}

	func visit(_ expr: LetDeclSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
//		try context.defineVariable(named: expr.name, as: context.get(expr).asType(in: context), at: expr.location)

		try .variable(expr.name, context.get(expr))
	}

	func visit(_ expr: MemberExprSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		if expr.receiver == nil {
			return try unresolvedReceiver(expr, context: context)
		}

		try inferenceVisitor.visit(expr, context)

		return try .value(context.get(expr).asType(in: context))
	}

	func visit(_ expr: TypeExprSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		try .value(context.get(expr).asType(in: context))
	}

	func visit(_ expr: ArrayLiteralExprSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		try .value(context.get(expr).asType(in: context))
	}

	func visit(_ expr: SubscriptExprSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		try .value(context.get(expr).asType(in: context))
	}

	func visit(_ expr: DictionaryLiteralExprSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		try .value(context.get(expr).asType(in: context))
	}

	func visit(_ expr: DictionaryElementExprSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		try .value(context.get(expr).asType(in: context))
	}

	func visit(_ expr: DefExprSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: IdentifierExprSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: UnaryExprSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: IfExprSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: WhileStmtSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: BlockStmtSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: FuncExprSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ParamsExprSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ParamSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: GenericParamsSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: DeclBlockSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ParseErrorSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ReturnStmtSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: InitDeclSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ImportStmtSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ExprStmtSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		try expr.expr.accept(self, context)
	}

	func visit(_ expr: IfStmtSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: StructDeclSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ProtocolDeclSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ProtocolBodyDeclSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: FuncSignatureDeclSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: EnumDeclSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: EnumCaseDeclSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: MatchStatementSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: CaseStmtSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: EnumMemberExprSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: InterpolatedStringExprSyntax, _: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	func visit(_ expr: ForStmtSyntax, _: Context) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	public func visit(_ expr: LogicalExprSyntax, _: Context) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	public func visit(_ expr: GroupedExprSyntax, _ context: Context) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	public func visit(_ expr: LetPatternSyntax, _ context: InferenceContext) throws -> Pattern.Argument {
		throw PatternError.invalid(expr.description)
	}

	// GENERATOR_INSERTION
}
