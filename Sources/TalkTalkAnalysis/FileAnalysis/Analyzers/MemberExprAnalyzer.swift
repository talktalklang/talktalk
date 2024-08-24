//
//  MemberExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import TalkTalkSyntax

struct MemberExprAnalyzer: Analyzer {
	let expr: any MemberExpr
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let receiver = try expr.receiver.accept(visitor, context)
		let propertyName = expr.property

		var member: (any Member)? = nil
		switch receiver.typeAnalyzed {
		case let .instance(receiverInstance):
			guard case let .struct(name) = receiverInstance.ofType,
			      let receiverStructType = context.lookupStruct(named: name)
			else {
				return error(
					at: expr, "Could not find type of \(receiverInstance)", environment: context,
					expectation: .identifier
				)
			}

			if let foundMember: any Member = receiverStructType.properties[propertyName] ?? receiverStructType.methods[propertyName] {
				if let varLetDecl = foundMember.expr as? VarLetDecl,
					 let typeExpr = varLetDecl.typeExpr {
					inferGenerics(
						memberTypeID: foundMember.typeID,
						typeExpr: typeExpr,
						receiverType: receiverStructType,
						receiverInstance: receiverInstance
					)
				}

				member = foundMember
			}
		default:
			return error(
				at: expr, "Cannot access property `\(propertyName)` on `\(receiver)` (\(receiver.typeAnalyzed.description))",
				environment: context,
				expectation: .member
			)
		}

		var errors: [AnalysisError] = []
		if member == nil, context.shouldReportErrors {
			errors.append(
				.init(
					kind: .noMemberFound(receiver: receiver, property: propertyName),
					location: receiver.location
				)
			)
		}

		return AnalyzedMemberExpr(
			typeID: member?.typeID ?? TypeID(.error("no member found")),
			expr: expr,
			environment: context,
			receiverAnalyzed: receiver as! any AnalyzedExpr,
			memberAnalyzed: member ?? error(at: expr, "no member found", environment: context, expectation: .member),
			analysisErrors: errors,
			isMutable: member?.isMutable ?? false
		)
	}

	func inferGenerics(memberTypeID: TypeID, typeExpr: TypeExpr, receiverType: StructType, receiverInstance: InstanceValueType) {
		if case var .instance(memberInstance) = memberTypeID.current,
			 case let .struct(memberStructName) = memberInstance.ofType,
			 let memberStruct = context.lookupStruct(named: memberStructName) {

			// Get the list of generic params this member has declared as part of its property
			for (i, genericParam) in (typeExpr.genericParams?.params ?? []).enumerated() {
				inferGenerics(memberTypeID: memberTypeID, typeExpr: genericParam.type, receiverType: memberStruct, receiverInstance: receiverInstance)

				if let receiverType = receiverInstance.boundGenericTypes[receiverType.typeParameters[0].name] {
					let memberTypeName = memberStruct.typeParameters[i].name
					memberInstance.boundGenericTypes[memberTypeName] = receiverType
				}
			}

			_ = memberTypeID.update(.instance(memberInstance), location: [typeExpr.identifier])
		}
	}

//
//	func inferGenerics(from receiver: TypeID, to memberTypeID: TypeID, memberType: StructType, typeExpr: any TypeExpr) {
//		// Check to see that we actually have types to infer. If not, no point in continuing.
//		guard case let .instance(receiverInstance) = receiver.current, !receiverInstance.boundGenericTypes.isEmpty else {
//			return
//		}
//
//		// Check that the member's type is an instance. Otherwise there won't be any generics to infer.
//		guard case var .instance(memberInstance) = memberTypeID.current else {
//			return
//		}
//
//		// Get the type parameter list from the declaration of this property. For example, if we have a struct like
//		//
//		//		struct Wrapper<Wrapped> {
//		//			let inner: Inner<Wrapped>
//		//		}
//		//
//		// Then the type parameter of the declaration is "Wrapped", which may not match whatever it's defined as in "Inner".
//		//
//		// If there aren't any, bail TODO: Maybe we want to pick up inferred types here somehow.
//		guard let propertyDeclGenerics = typeExpr.genericParams?.params else {
//			return
//		}
//
//		// Do the recursive inference so that we can update memberInstance.boundGenericTypes with the appropriate inferences
//		// Iterate through the member's struct type parameters, trying to infer the correct types from the receiver's bound generic types
//		for (index, param) in propertyDeclGenerics.enumerated() {
//			inferGenerics(from: receiver, to: memberTypeID, memberType: memberType, typeExpr: param.type)
//
//			// Ensure that the struct we're inferring has enough type parameters to infer
//			guard index < memberType.typeParameters.count else {
//				continue
//			}
//
//			let memberTypeParam = memberType.typeParameters[index].name
//			let genericParam = param.type.identifier.lexeme
//
//			// Try to find the generic type in the receiver's bound types
//			if let inferredType = receiverInstance.boundGenericTypes[genericParam] {
//				// Map this inferred type to the member's type parameter, so it can be propagated
//				memberInstance.boundGenericTypes[memberTypeParam] = inferredType
//			}
//		}
//
//		_ = memberTypeID.update(.instance(memberInstance), location: typeExpr.location)
//	}
}
