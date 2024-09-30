//
//  CallConstraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import OrderedCollections
import TalkTalkCore

struct CallConstraint: Constraint {
	let callee: InferenceResult
	let args: [InferenceResult]
	let returns: InferenceResult
	let location: SourceLocation
	let isRetry: Bool

	func result(in context: InferenceContext) -> String {
		let callee = context.applySubstitutions(to: callee.asType(in: context))
		let args = args.map { context.applySubstitutions(to: $0.asType(in: context)) }.map(\.description).joined(separator: ", ")
		let returns = context.applySubstitutions(to: returns)

		return "CallConstraint(callee: \(callee.debugDescription), args: \(args.debugDescription), returns: \(returns.debugDescription))"
	}

	var description: String {
		"CallConstraint(callee: \(callee.debugDescription), args: \(args.debugDescription), returns: \(returns.debugDescription))"
	}

	func solve(in context: InferenceContext) -> ConstraintCheckResult {
		let callee = context.applySubstitutions(
			to: callee.asType(in: context)
		)

		switch callee {
		case let .function(params, fnReturns):
			return solveFunction(params: params, fnReturns: fnReturns, in: context)
		case let .instantiatable(.struct(structType)):
			return solveStruct(structType: structType, in: context)
		case let .enumCase(enumCase):
			return solveEnumCase(enumCase: enumCase, in: context)
		case let .placeholder(typeVar):
			// If it's a type var that we haven't solved yet, try deferring
			if isRetry {
				context.log("Deferred constraint not fulfilled", prefix: " ! ")
				return .error([
					Diagnostic(message: "\(typeVar) not callable", severity: .error, location: location),
				])
			} else {
				// If we can't find the callee, then add a constraint to the end of the list to see if we end up finding it later
				context.log("Deferring call constraint on \(typeVar)", prefix: " ? ")
				context.deferConstraint(.call(.type(callee), args, returns: returns, at: location, isRetry: true))
				return .ok
			}
		case let .optional(type):
			if args.count != 1 {
				return .error([.init(message: "Wth is \(type)(\(args.count))", severity: .error, location: location)])
			}

			context.unify(type, context.applySubstitutions(to: args[0]), location)
			return .ok
		case let .error(error):
			if case let .undefinedVariable(name) = error.kind {
				if isRetry {
					context.log("Deferred constraint not fulfilled", prefix: " ! ")
					return .error([
						Diagnostic(message: "\(callee) not callable", severity: .error, location: location),
					])
				} else {
					// If we can't find the callee, then add a constraint to the end of the list to see if we end up finding it later
					context.log("Deferring call constraint on \(name)", prefix: " ? ")
					context.deferConstraint(.call(.type(callee), args, returns: returns, at: location, isRetry: true))
				}
				return .ok
			}

			return .error([
				Diagnostic(message: "\(callee) not callable", severity: .error, location: location),
			])
		default:
			return .error([
				Diagnostic(message: "\(returns) not callable", severity: .error, location: location),
			])
		}
	}

	func solveFunction(params: [InferenceResult], fnReturns: InferenceResult, in context: InferenceContext) -> ConstraintCheckResult {
		if args.count != params.count {
			context.addError(.init(kind: .argumentError(expected: params.count, actual: args.count), location: location))

			return .error([
				Diagnostic(
					message: "Expected \(params.count) args, got \(args.count)",
					severity: .error,
					location: location
				),
			])
		}

		// Create a child context to evaluate args and params so we don't get leaks
		let childContext = context.childContext()

		for (arg, param) in zip(args, params) {
			let arg = context.applySubstitutions(to: arg)
			let param = context.applySubstitutions(to: param)

			if arg != param {
				childContext.unify(arg, param, location)
			}
		}

		if returns != fnReturns {
			childContext.unify(
				childContext.applySubstitutions(to: returns),
				childContext.applySubstitutions(to: fnReturns),
				location
			)
		}

		context.unify(context.applySubstitutions(to: returns), childContext.applySubstitutions(to: returns), location)

		return .ok
	}

	// Handle inits for structs
	func solveStruct(structType: StructType, in context: InferenceContext) -> ConstraintCheckResult {
		// Create a child context to evaluate args and params so we don't get leaks
		let childContext = structType.context
		let params: [InferenceResult]

		// Create a local substitutions map for this instance
		var substitutions: OrderedDictionary<TypeVariable, InferenceType> = [:]

		// If we have an init, use the params from that init
		if let initializer = structType.initializers["init"] {
			switch initializer {
			case let .scheme(scheme):
				switch structType.context.instantiate(scheme: scheme) {
				case let .function(fnParams, _):
					params = fnParams
				default:
					params = []
				}
			case let .type(.function(fnParams, _)):
				params = fnParams
			default:
				params = []
			}
		} else {
			// We don't have an init so we need to synthesize one from the struct's properties
			params = structType.properties.map { name, type in
				if case let .type(.typeVar(typeVar)) = type,
				   structType.typeContext.typeParameters.contains(typeVar)
				{
					let fresh: InferenceType = context.freshTypeVariable(name, file: #file, line: #line)
					substitutions[typeVar] = fresh
					return .type(fresh)
				}

				return type
			}
		}

		let instance = structType.instantiate(with: substitutions, in: context)
		context.unify(context.applySubstitutions(to: returns), .instance(instance), location)

		if args.count != params.count {
			return .error([
				Diagnostic(
					message: "Expected \(params.count) args, got \(args.count)",
					severity: .error,
					location: location
				),
			])
		}

		guard case var .instance(instance) = context.applySubstitutions(to: returns) else {
			return .error([.init(message: "did not get instance, got: \(returns)", severity: .error, location: location)])
		}

		for (arg, param) in zip(args, params) {
			let paramType: InferenceType

			switch context.applySubstitutions(to: param) {
			case let .typeVar(param):
				// If the member type is generic, we need to swap it out for the instance's copy so we don't unify
				// for the whole struct.
				if let instanceType = instance.substitutions[param] {
					paramType = instanceType
				} else {
					paramType = .typeVar(param)
				}

				let type = arg.asType(in: childContext)
				instance.substitutions[param] = type
				childContext.unify(type, arg.asType(in: childContext), location)
			case let .instantiatable(structType):
				var substitutions: OrderedDictionary<TypeVariable, InferenceType> = [:]
				if case let .instance(instance) = context.applySubstitutions(to: arg.asType(in: context)) {
					substitutions = instance.substitutions
				}

				paramType = .instance(
					structType.instantiate(
						with: substitutions,
						in: context
					)
				)

				instance.substitutions.merge(substitutions) { $1 }
			default:
				paramType = childContext.applySubstitutions(to: param)
			}

			context.unify(
				arg.asType(in: childContext),
				paramType,
				location
			)
		}

		childContext.unify(
			.instance(instance),
			returns.asType(in: context),
			location
		)

		context.unify(childContext.applySubstitutions(to: returns), childContext.applySubstitutions(to: returns), location)

		return .ok
	}

	func solveEnumCase(enumCase: EnumCase, in context: InferenceContext) -> ConstraintCheckResult {
		// We need to unify the enum case attached types with args here

		// The naive thing which is too global
//		for (type, arg) in zip(enumCase.attachedTypes, args) {
//			context.unify(type, arg.asType(in: context), location)
//		}

		context.unify(returns.asType(in: context), .enumCase(enumCase), location)
		return .ok
	}
}

extension Constraint where Self == CallConstraint {
	static func call(_ callee: InferenceResult, _ args: [InferenceResult], returns: InferenceResult, at: SourceLocation, isRetry: Bool = false) -> CallConstraint {
		CallConstraint(callee: callee, args: args, returns: returns, location: at, isRetry: isRetry)
	}
}
