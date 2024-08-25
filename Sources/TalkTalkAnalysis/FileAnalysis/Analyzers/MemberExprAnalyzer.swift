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
				// Start out by just filling in the bound generic types with placeholders
				if case var .instance(instance) = foundMember.typeID.current,
					 case let .struct(memberTypeName) = instance.ofType,
					 let memberType = context.lookupStruct(named: memberTypeName) {
					for typeParameter in memberType.typeParameters {
						instance.boundGenericTypes[typeParameter.name] = TypeID(.placeholder)
					}

					foundMember.typeID.update(.instance(instance), location: expr.location)
				}

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
			typeID: member?.typeID ??
				TypeID(.error("no member found: \(expr.property)")),
			expr: expr,
			environment: context,
			receiverAnalyzed: receiver as! any AnalyzedExpr,
			memberAnalyzed: member ?? error(at: expr, "no member found", environment: context, expectation: .member),
			analysisErrors: errors,
			isMutable: member?.isMutable ?? false
		)
	}

	func inferGenerics(memberTypeID: TypeID, typeExpr: TypeExpr, receiverType: StructType, receiverInstance: InstanceValueType) {
		if self.expr.description == "self.store" {
			
		}
		guard case var .instance(memberInstance) = memberTypeID.current else {
			return
		}

		if case let .struct(memberStructName) = memberInstance.ofType,
			 let memberStruct = context.lookupStruct(named: memberStructName) {

			// Get the list of generic params this member has declared as part of its property
			for (i, genericParam) in (typeExpr.genericParams?.params ?? []).enumerated() {
				guard memberStruct.typeParameters.count > i else {
					continue
				}

				inferGenerics(memberTypeID: memberTypeID, typeExpr: genericParam.type, receiverType: memberStruct, receiverInstance: receiverInstance)

				if receiverType.typeParameters.count > i, let receiverType = receiverInstance.boundGenericTypes[receiverType.typeParameters[i].name] {
					let memberTypeName = memberStruct.typeParameters[i].name
					memberInstance.boundGenericTypes[memberTypeName] = receiverType
				} else if let receiverType = context.type(named: genericParam.type.identifier.lexeme, asInstance: true) {
					let memberTypeName = memberStruct.typeParameters[i].name
					memberInstance.boundGenericTypes[memberTypeName]?.update(receiverType, location: genericParam.type.location)
				}
			}

			_ = memberTypeID.update(.instance(memberInstance), location: [typeExpr.identifier])
		}
	}
}
