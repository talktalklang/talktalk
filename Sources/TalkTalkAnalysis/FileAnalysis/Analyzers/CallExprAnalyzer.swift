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
				wrapped: $0,
				expr: $0.value.accept(visitor, context) as! any AnalyzedExpr
			)
		}

		// What type will this AnalyzedCallExpr eventually be
		var type: TypeID

		// How many arguments are expected to be passed to this call
		let arity: Int

		if let callee = callee.as(AnalyzedVarExpr.self), callee.name == "_cast" {
			if let variable = args[0].expr.as(AnalyzedVarExpr.self) {
				switch args[1].expr {
				case let arg as AnalyzedVarExpr:
					if let type = context.type(named: arg.name, asInstance: true) {
						variable.typeID.update(type, location: variable.location)
					}
				case let arg as AnalyzedTypeExpr:
					if case let .struct(name) = arg.typeAnalyzed,
						 let structType = context.lookupStruct(named: name) {
						variable.typeID.update(.instance(.struct(name, structType.placeholderGenericTypes())), location: variable.location)
					} else {
						variable.typeID.update(arg.typeAnalyzed, location: variable.location)
					}
				default:
					()
				}
			} else {
				errors.append(.init(kind: .undefinedVariable("First argument to _cast must be a variable"), location: callee.location))
			}
		}

		switch callee.typeAnalyzed {
		case let .function(funcName, returning, params, _):
			if params.count == args.count {
				// Try to infer param types, or check types if we already have one
				for (i, param) in params.enumerated() {
					if case .placeholder = param.typeID.type() {
						if param.name == "item" {

						}
						// FIXME: This is binding too globally. We need to figure out a way to scope this more locally
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
					returning = try visitor.visit(funcExpr.body, env).typeID
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

		// Handle bound functions, like if `let wrapper = Wrapper<Wrapped>(wrapped: 123)`, then calling wrapper.wrapped
		// should be known to be an int.
		if let receiver = callee.as(AnalyzedMemberExpr.self)?.receiverAnalyzed,
			 case let .instance(receiverInstance) = receiver.typeID.current,
			 case let .instance(memberInstance) = type.current,
			 case let .generic(receiverInstance.ofType, genericName) = memberInstance.ofType,
		   let resolvedTypeID = receiverInstance.boundGenericTypes[genericName] {
			type.infer(from: resolvedTypeID)
		}

		return AnalyzedCallExpr(
			typeID: type,
			wrapped: expr.cast(CallExprSyntax.self),
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

		var instanceType = InstanceValueType.struct(name, structType.placeholderGenericTypes())

		if let callee = callee as? AnalyzedTypeExpr,
		   let calleeGenericParams = callee.genericParams, !calleeGenericParams.isEmpty
		{
			// Fill in type parameters if they're explicitly annotated. If they're not we'll have to try to infer them.
			if calleeGenericParams.count == structType.typeParameters.count {
				for (i, structTypeParam) in structType.typeParameters.enumerated() {
					// We always get back a Type from visiting a TypeExpr (duh) but we want an instance for the case where
					// the type is a Struct. But if it's a primitive (like an int) then we can just set it directly.
					let type = try calleeGenericParams.params[i].type.accept(visitor, context).typeID

					if case let .struct(name) = type.current {
						if let structType = context.lookupStruct(named: name) {
							// Reserve placeholders for the type parameters of this struct
							let structTypeParams: [String: TypeID] = structType.typeParameters.reduce(into: [:]) { res, param in
								res[param.name] = TypeID(.placeholder)
							}

							type.update(.instance(.struct(name, structTypeParams)), location: callee.location)
						} else {
							errors.append(.init(kind: .typeNotFound(name), location: callee.location))
						}
					}

					instanceType.boundGenericTypes[structTypeParam.name] = type
				}
			} else if context.shouldReportErrors {
				errors.append(
					context.report(.typeParameterError(
						expected: structType.typeParameters.count,
						received: calleeGenericParams.count
					), at: expr.location)
				)
			}
		} else if !structType.typeParameters.isEmpty, let initFn = structType.methods["init"] {
			// Start out by just filling in the bound generic types with placeholders
			for typeParameter in structType.typeParameters {
				instanceType.boundGenericTypes[typeParameter.name] = TypeID(.placeholder)
			}

			// Try to infer type parameters from init
			for (i, arg) in args.enumerated() {
				// See if we have a label for the arg (could maybe rely on positions here??)
				// Find the param definition from the init
				let param = initFn.params[i]

				if case let .instance(paramInstanceType) = param.typeID.current,
				   case let .generic(.struct(structType.name!), typeName) = paramInstanceType.ofType
				{
					instanceType.boundGenericTypes[typeName]?.infer(from: arg.expr.typeID)
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

		// How can we bind this instance type to `self` inside the struct.......
		let type = TypeID(.instance(instanceType))
		let arity = structType.methods["init"]!.params.count

		return (type, arity, errors)
		// TODO: also type check args better?
	}

	func inferGenerics(type structType: StructType, paramTypeExpr: TypeExpr, argumentTypeID: TypeID, instance: inout InstanceValueType, context: Environment) {
		// Through the struct's type parameters and see if any of them are being used by this parameter. For example
		// if the struct is Wrapper<Wrapped> and the param's type is Inner<Wrapped>, and we know the type of Inner.Wrapped
		// in this case, then we can bind the wrapper's Wrapped type for this instance.
		for typeParameter in structType.typeParameters {
			// For each of the generic parameters of this parameter (for example, init(inner: Inner<Wrapped>) would have [Wrapped] here)
			for (i, genericParam) in (paramTypeExpr.genericParams?.params ?? []).enumerated() {
				// Recurse through to see if there are any more types we could match
				inferGenerics(type: structType, paramTypeExpr: genericParam.type, argumentTypeID: argumentTypeID, instance: &instance, context: context)

				// If Wrapped (from Wrapper<Wrapped>) is being used by the param (like Inner<Wrapped>) then we can try to pull the
				// bound value off the argument
				if typeParameter.name == genericParam.type.identifier.lexeme {
					// Make sure the type of the arg support generics. If so, get the arg's name for the generic that's being
					// inferred here. Otherwise bail. TODO: This might want to error?
					guard case let .instance(instanceInfo) = argumentTypeID.current,
								// Get the argument type's name so we can look up actual type
								case let .struct(name) = instanceInfo.ofType,
								// Look up the type by name
								let argOfType = context.lookupStruct(named: name),
								// Make sure the type has enough type parameters so we don't crash on an index error
								argOfType.typeParameters.count > i
					else {
						continue
					}

					let argTypeParameter = argOfType.typeParameters[i].name
					instance.boundGenericTypes[typeParameter.name] = instanceInfo.boundGenericTypes[argTypeParameter]
				}
			}

			// Handle the simple case of Wrapper<Wrapped> { init(inner: Wrapped) } getting passed a type we know about
			if typeParameter.type.identifier.lexeme == paramTypeExpr.identifier.lexeme {
				instance.boundGenericTypes[typeParameter.name] = TypeID(inferredFrom: argumentTypeID)
			}
		}
	}
}
