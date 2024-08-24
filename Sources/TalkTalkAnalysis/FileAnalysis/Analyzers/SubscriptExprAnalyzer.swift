//
//  SubscriptExprAnalyzer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/24/24.
//

import TalkTalkSyntax

struct SubscriptExprAnalyzer {
	let expr: any SubscriptExpr
	let visitor: SourceFileAnalyzer
	let context: Environment

	func analyze() throws -> any AnalyzedSyntax {
		let receiver = try expr.receiver.accept(visitor, context) as! any AnalyzedExpr
		let args = try expr.args.map { try $0.accept(visitor, context) } as! [AnalyzedArgument]

		var result = AnalyzedSubscriptExpr(
			receiverAnalyzed: receiver,
			argsAnalyzed: args,
			wrapped: expr,
			typeID: TypeID(.placeholder),
			environment: context,
			analysisErrors: []
		)

		guard case let .instance(instance) = receiver.typeAnalyzed,
					case let .struct(structName) = instance.ofType,
					let structType = context.lookupStruct(named: structName),
					let getMethod = structType.methods["get"]
		else {
			result.analysisErrors = [
				AnalysisError(kind: .noMemberFound(receiver: receiver, property: "get"), location: expr.location),
			]

			return result
		}

		result.typeID = getMethod.returnTypeID.resolve(with: instance)

		if let funcExpr = getMethod.expr as? any FuncExpr, let typeExpr = funcExpr.typeDecl {
			inferGenerics(
				memberTypeID: result.typeID,
				typeExpr: typeExpr,
				receiverType: structType,
				receiverInstance: instance
			)
		}

		return result
	}

	func inferGenerics(memberTypeID: TypeID, typeExpr: TypeExpr, receiverType: StructType, receiverInstance: InstanceValueType) {
		guard case var .instance(memberInstance) = memberTypeID.current else {
			return
		}

		if case let .struct(memberStructName) = memberInstance.ofType,
			 let memberStruct = context.lookupStruct(named: memberStructName) {

			// Get the list of generic params this member has declared as part of its property
			for (i, genericParam) in (typeExpr.genericParams?.params ?? []).enumerated() {
				guard receiverType.typeParameters.count > i, memberStruct.typeParameters.count > i else {
					continue
				}

				inferGenerics(memberTypeID: memberTypeID, typeExpr: genericParam.type, receiverType: memberStruct, receiverInstance: receiverInstance)

				if let receiverType = receiverInstance.boundGenericTypes[receiverType.typeParameters[i].name] {
					let memberTypeName = memberStruct.typeParameters[i].name
					memberInstance.boundGenericTypes[memberTypeName] = receiverType
				}
			}

			_ = memberTypeID.update(.instance(memberInstance), location: [typeExpr.identifier])
		}
	}
}
