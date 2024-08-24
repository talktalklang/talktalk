//
//  CallExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkSyntax

struct CallExprAnalyzer: Analyzer {
	enum CallExprError: Error, @unchecked Sendable {
		case structNotFound(AnalyzedErrorSyntax)
	}

	let expr: any CallExpr
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let callee = try expr.callee.accept(visitor, context)
		var errors: [AnalysisError] = []

		let args = try expr.args.map {
			try AnalyzedArgument(
				environment: context,
				label: $0.label,
				expr: $0.value.accept(visitor, context) as! any AnalyzedExpr
			)
		}

		// What type will this AnalyzedCallExpr eventually be
		let type: TypeID

		// How many arguments are expected to be passed to this call
		let arity: Int

		switch callee.typeAnalyzed {
		case let .function(funcName, returning, params, _):
			if params.count == args.count {
				// Try to infer param types, or check types if we already have one
				for (i, param) in params.enumerated() {
					if case .placeholder = param.typeID.type() {
						param.typeID.update(args[i].expr.typeAnalyzed, location: callee.location)
					} else if context.shouldReportErrors {
						errors.append(contentsOf: checkAssignment(to: param, value: args[i].expr, in: context))
					}
				}
			}

			var returning = returning
			if returning.type() == .placeholder {
				var funcExpr: AnalyzedFuncExpr? = nil

				if let callee = callee.as(AnalyzedFuncExpr.self) {
					funcExpr = callee
				} else if let callee = callee.as(AnalyzedVarExpr.self),
				          let calleeFunc = context.lookup(callee.name)?.expr.as(AnalyzedFuncExpr.self)
				{
					funcExpr = calleeFunc
				}

				// Don't try this on recursive functions, it doesn't end well. Well actually
				// it just doesn't end.
				if let funcExpr, funcExpr.name?.lexeme != funcName {
					let env = funcExpr.environment.add(namespace: funcName)
					for param in params {
						env.update(local: param.name, as: param.typeID.current)
					}
					// Try to infer return type now that we know what a param is
					returning = try visitor.visit(funcExpr.bodyAnalyzed, env).typeID
				}
			}

			type = returning
			arity = params.count
		case let .struct(structName):
			let (callType, callArity, callErrors) = try analyzeStruct(callee: callee, named: structName, args: args)
			errors.append(contentsOf: callErrors)
			type = callType
			arity = callArity
		default:
			type = TypeID(.any)
			arity = -1

			// Append the callee not callable error if we don't already have an error
			// on this callee node.
			if callee.analysisErrors.isEmpty {
				errors.append(
					AnalysisError(
						kind: .unknownError("Callee not callable: \(callee.typeAnalyzed)"),
						location: callee.location
					)
				)
			}
		}

		if arity != args.count {
			errors.append(
				context.report(.argumentError(expected: arity, received: args.count), at: expr.location)
			)
		}

		return AnalyzedCallExpr(
			typeID: type,
			expr: expr,
			calleeAnalyzed: callee as! any AnalyzedExpr,
			argsAnalyzed: args,
			analysisErrors: errors,
			environment: context
		)
	}

	func analyzeStruct(callee: any AnalyzedSyntax, named name: String, args: [AnalyzedArgument]) throws -> (TypeID, Int, [AnalysisError]) {
		var errors: [AnalysisError] = []

		guard let structType = context.lookupStruct(named: name) else {
			throw CallExprError.structNotFound(error(
				at: callee, "could not find struct named: \(name)",
				environment: context,
				expectation: .decl
			))
		}

		var instanceType = InstanceValueType.struct(name)

		if let callee = callee as? AnalyzedTypeExpr,
		   let params = callee.genericParams, !params.isEmpty
		{
			// Fill in type parameters if they're explicitly annotated. If they're not we'll have to try to infer them.
			if params.count == structType.typeParameters.count {
				for (i, param) in structType.typeParameters.enumerated() {
					let type = try params.params[i].type.accept(visitor, context).typeID
					instanceType.boundGenericTypes[param.name] = type
				}
			} else if context.shouldReportErrors {
				errors.append(
					context.report(.typeParameterError(
						expected: structType.typeParameters.count,
						received: params.count
					), at: expr.location)
				)
			}
		} else if !structType.typeParameters.isEmpty, let initFn = structType.methods["init"] {
			// Try to infer type parameters from init
			for (i, arg) in args.enumerated() {
				// See if we have a label for the arg (could maybe rely on positions here??)
				// Find the param definition from the init
				let param = initFn.params[i]

				if case let .instance(paramInstanceType) = param.typeID.current,
				   case let .generic(.struct(structType.name!), typeName) = paramInstanceType.ofType
				{
					instanceType.boundGenericTypes[typeName] = arg.expr.typeID
				}

				// If the parameter type is generic and we know the type of the argument, we can use that to
				// set the generic type of the instance
				if param.typeID.current == .placeholder {
					param.typeID.infer(from: arg.typeID)
				}

				if let paramTypeExpr = param.type {
					inferGenerics(type: structType, paramTypeExpr: paramTypeExpr, argumentTypeID: arg.typeID, instance: &instanceType, context: context)
				}
			}
		}

		let type = TypeID(.instance(instanceType))
		let arity = structType.methods["init"]!.params.count

		return (type, arity, errors)
		// TODO: also type check args better?
	}
}
