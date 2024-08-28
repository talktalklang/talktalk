//
//  CallConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkSyntax

struct CallConstraint: Constraint {
	let callee: InferenceResult
	let args: [InferenceResult]
	let returns: InferenceType
	let location: SourceLocation

	func result(in context: InferenceContext) -> String {
		let callee = context.applySubstitutions(to: callee.asType(in: context))
		let args = args.map { context.applySubstitutions(to: $0.asType(in: context)) }.map(\.description).joined(separator: ", ")
		let returns = context.applySubstitutions(to: returns)

		return "CallConstraint(callee: \(callee), args: \(args), returns: \(returns))"
	}

	var description: String {
		"CallConstraint(callee: \(callee), args: \(args), returns: \(returns))"
	}

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let callee = context.applySubstitutions(
			to:	callee.asType(in: context)
		)

		switch callee {
		case .function(let params, let fnReturns):
			return solveFunction(params: params, fnReturns: fnReturns, in: context)
		case .structType(let structType):
			return solveStruct(structType: structType, in: context)
		default:
			return .error([
				Diagnostic(message: "\(callee) not callable", severity: .error, location: location)
			])
		}
	}

	func solveFunction(params: [InferenceType], fnReturns: InferenceType, in context: InferenceContext) -> ConstraintCheckResult {
		if args.count != params.count {
			return .error([
				Diagnostic(
					message: "Expected \(params.count) args, got \(args.count)",
					severity: .error,
					location: location
				)
			])
		}

		// Create a child context to evaluate args and params so we don't get leaks
		let childContext = context.childContext()

		for (arg, param) in zip(args, params) {
			childContext.unify(
				arg.asType(in: context),
				param
			)
		}

		if returns != fnReturns {
			childContext.unify(
				childContext.applySubstitutions(to: returns),
				childContext.applySubstitutions(to: fnReturns)
			)
		}

		context.unify(returns, childContext.applySubstitutions(to: returns))

		return .ok
	}

	func solveStruct(structType: StructType, in context: InferenceContext) -> ConstraintCheckResult {
		let params: [InferenceType] = if let initializer = structType.initializers["init"] {
			switch initializer {
			case .scheme(let scheme):
				switch structType.context.instantiate(scheme: scheme) {
				case .function(let params, _):
					params.map {
						structType.context.applySubstitutions(to: $0)
					}
				default:
					[]
				}
			case .type(.function(let params, _)):
				params
			default:
				[]
			}
		} else {
			structType.properties.values.map({ $0.asType(in: structType.context) })
		}

		if args.count != params.count {
			return .error([
				Diagnostic(
					message: "Expected \(params.count) args, got \(args.count)",
					severity: .error,
					location: location
				)
			])
		}

		// Create a child context to evaluate args and params so we don't get leaks
		let childContext = structType.context//.childTypeContext(withSelf: structTypeOriginal.typeContext.selfVar)

		for (arg, param) in zip(args, params) {
//			if case let .typeVar(typeVariable) = param, let name = typeVariable.name {
//				if let existing = childContext.lookupVariable(named: name) {
//					childContext.unify(
//						childContext.applySubstitutions(to: existing),
//						arg.asType(in: childContext)
//					)
//				}
//			}

			childContext.unify(
				arg.asType(in: childContext),
				param
			)
		}

		childContext.unify(returns, .structInstance(structType.copy()))
		context.unify(returns, childContext.applySubstitutions(to: returns))

		return .ok
	}
}

extension Constraint where Self == CallConstraint {
	static func call(_ callee: InferenceResult, _ args: [InferenceResult], returns: InferenceType, at: SourceLocation) -> CallConstraint {
		CallConstraint(callee: callee, args: args, returns: returns, location: at)
	}
}
