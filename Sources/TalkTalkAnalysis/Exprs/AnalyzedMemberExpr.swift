//
//  AnalyzedMemberExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct AnalyzedMemberExpr: AnalyzedExpr, MemberExpr {
	public let typeID: TypeID
	let expr: MemberExpr
	public var analyzedChildren: [any AnalyzedSyntax] { [receiverAnalyzed] }
	public let environment: Environment

	public let receiverAnalyzed: any AnalyzedExpr
	public let memberAnalyzed: any Member
	public let analysisErrors: [AnalysisError]

	public var receiver: any Expr { expr.receiver }
	public var property: String { expr.property }
	public var propertyToken: Token { expr.propertyToken }
	public var isMutable: Bool
	public var location: SourceLocation { expr.location }
	public var children: [any Syntax] { expr.children }

	public func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value {
		try visitor.visit(self, scope)
	}

	public func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	public func definition() -> Definition? {
		switch receiverAnalyzed.typeAnalyzed {
		case let .instance(instanceType):
			switch instanceType.ofType {
			case let .struct(name):
				guard let structDef = environment.lookupStruct(named: name) else {
					return nil
				}

				// Look to see if the property is a method
				if let method = structDef.methods[property],
				   let funcDef = method.expr as? any FuncExpr
				{
					let token = funcDef.name ?? funcDef.funcToken
					return Definition(token: token, type: method.typeID.current)
				}

				// See if it's a property
				if let property = structDef.properties[property],
				   let propDef = property.expr as? any VarLetDecl
				{
					return Definition(token: propDef.nameToken, type: property.typeID.current)
				}
			default:
				()
			}
		default:
			()
		}

		return nil
	}
}
