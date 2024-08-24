//
//  Analyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkSyntax

public protocol Analyzer {}

extension Analyzer {
	func infer(_ exprs: [any AnalyzedExpr], in env: Environment) {
		let type = exprs.map(\.typeID.current).max(by: { $0.specificity < $1.specificity }) ?? .placeholder

		for var expr in exprs {
			if let exprStmt = expr as? AnalyzedExprStmt {
				// Unwrap expr stmt
				expr = exprStmt.exprAnalyzed
			}

			if let expr = expr as? AnalyzedVarExpr {
				expr.typeID.update(type, location: expr.location)
				env.update(local: expr.name, as: type)
				if let capture = env.captures.first(where: { $0.name == expr.name }) {
					capture.binding.type.update(type, location: expr.location)
				}
			}
		}
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

	func checkAssignment(
		to receiver: any Typed,
		value: any AnalyzedExpr,
		in env: Environment
	) -> [AnalysisError] {
		var errors: [AnalysisError] = []

		if !env.shouldReportErrors {
			return errors
		}

		errors.append(contentsOf: checkMutability(of: receiver, in: env))

		if value.typeID.current == .placeholder {
			value.typeID.update(receiver.typeID.current, location: value.location)
		}

		if receiver.typeID.current.isAssignable(from: value.typeAnalyzed) {
			receiver.typeID.update(value.typeID.current, location: value.location)
			return errors
		}

		errors.append(
			AnalysisError(
				kind: .typeCannotAssign(
					expected: receiver.typeID,
					received: value.typeID
				),
				location: value.location
			)
		)

		return errors
	}

	func checkMutability(of receiver: any Typed, in env: Environment) -> [AnalysisError] {
		switch receiver {
		case let receiver as AnalyzedVarExpr:
			let binding = env.lookup(receiver.name)

			if !receiver.isMutable || (binding?.isMutable == false) {
				return [
					AnalysisError(
						kind: .cannotReassignLet(variable: receiver),
						location: receiver.location
					),
				]
			}
		case let receiver as AnalyzedMemberExpr:
			if !receiver.isMutable {
				return [AnalysisError(
					kind: .cannotReassignLet(variable: receiver),
					location: receiver.location
				)]
			}
		default:
			()
		}

		return []
	}

	func error(
		at expr: any Syntax, _ message: String, environment: Environment, expectation: ParseExpectation
	) -> AnalyzedErrorSyntax {
		AnalyzedErrorSyntax(
			typeID: TypeID(.error(message)),
			expr: ParseErrorSyntax(location: expr.location, message: message, expectation: expectation),
			environment: environment
		)
	}
}
