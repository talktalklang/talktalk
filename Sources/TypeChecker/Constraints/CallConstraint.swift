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
			to: callee.asType(in: context)
		)

		switch callee {
		case .function(let params, let fnReturns):
			return solveFunction(params: params, fnReturns: fnReturns, in: context)
		case .structType(let structType):
			return solveStruct(structType: structType, in: context)
		default:
			return .error([
				Diagnostic(message: "\(returns) not callable", severity: .error, location: location)
			])
		}
	}

	func solveFunction(params: [InferenceType], fnReturns: InferenceType, in context: InferenceContext) -> ConstraintCheckResult {
		if args.count != params.count {
			context.addError(.init(kind: .argumentError(expected: params.count, actual: args.count), location: location))

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
			if arg.asType(in: context) != param {
				childContext.unify(
					arg.asType(in: context),
					param,
					location
				)
			}
		}

		if returns != fnReturns {
			childContext.unify(
				childContext.applySubstitutions(to: returns),
				childContext.applySubstitutions(to: fnReturns),
				location
			)
		}

		context.unify(returns, childContext.applySubstitutions(to: returns), location)

		return .ok
	}

	func solveStruct(structType: StructType, in context: InferenceContext) -> ConstraintCheckResult {
		// Create a child context to evaluate args and params so we don't get leaks
		let childContext = structType.context
//		let childContext = structType.context.childTypeContext(withSelf: structType.context.typeContext!.selfVar)
		let params: [InferenceType]
		if let initializer = structType.member(named: "init") {
			switch initializer {
			case .scheme(let scheme):
				switch structType.context.instantiate(scheme: scheme) {
				case .function(let fnParams, let fnReturns):
					context.unify(returns, fnReturns, location)
					params = fnParams
				default:
					params = []
				}
			case .type(.function(let fnParams, _)):
				params = fnParams
			default:
				params = []
			}
		} else {
			var substitutions: [TypeVariable: InferenceType] = [:]

			params = structType.properties.map { name, type in
				if case .type(.typeVar(let typeVar)) = type,
				   structType.typeContext.typeParameters.contains(typeVar)
				{
					substitutions[typeVar] = context.freshTypeVariable("\(name) [init]", file: #file, line: #line)
					return substitutions[typeVar]!
				}

				return type.asType(in: structType.context)
			}

			let instance = structType.instantiate(with: substitutions, in: context)
			context.unify(returns, .structInstance(instance), location)
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

		guard case .structInstance(let instance) = context.applySubstitutions(to: returns) else {
			return .error([.init(message: "did not get instance, got: \(returns)", severity: .error, location: location)])
		}

		for (arg, param) in zip(args, params) {
			// TODO: Deal with struct instances as args???

			let paramType: InferenceType

			switch context.applySubstitutions(to: param) {
			case .typeVar(let param):
				// If the member type is generic, we need to swap it out for the instance's copy so we don't unify
				// for the whole struct.
				if let instanceType = instance.substitutions[param] {
					paramType = instanceType
				} else {
					paramType = .typeVar(param)
				}

				instance.substitutions[param] = arg.asType(in: childContext)
				childContext.unify(instance.substitutions[param]!, arg.asType(in: childContext), location)
			case .structType(let structType):
				var substitutions: [TypeVariable: InferenceType] = [:]
				if case .structInstance(let instance) = context.applySubstitutions(to: arg.asType(in: context)) {
					substitutions = instance.substitutions
				}

				paramType = .structInstance(
					structType.instantiate(
						with: substitutions,
						in: context
					)
				)

				instance.substitutions.merge(substitutions) { $1 }
			default:
				paramType = param
			}

			context.unify(
				arg.asType(in: childContext),
				paramType,
				location
			)
		}

		childContext.unify(
			.structInstance(instance),
			returns,
			location
		)

		context.unify(returns, childContext.applySubstitutions(to: returns), location)

		return .ok
	}
}

extension Constraint where Self == CallConstraint {
	static func call(_ callee: InferenceResult, _ args: [InferenceResult], returns: InferenceType, at: SourceLocation) -> CallConstraint {
		CallConstraint(callee: callee, args: args, returns: returns, location: at)
	}
}
