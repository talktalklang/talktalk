//
//  AnalyzedSyntax.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public protocol AnalyzedSyntax: Syntax {
	var typeID: TypeID { get }
	var analyzedChildren: [any AnalyzedSyntax] { get }
	var analysisErrors: [AnalysisError] { get }

	func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor
}

public extension AnalyzedSyntax {
	var typeAnalyzed: ValueType {
		typeID.current
	}

	var analysisErrors: [AnalysisError] { [] }

	func collectErrors() -> [AnalysisError] {
		var result = analysisErrors
		for child in self.analyzedChildren {
			result.append(contentsOf: child.collectErrors())
		}
		return result
	}

	var debugDescription: String {
		"\(Self.self)(analyzedChildren: [\(analyzedChildren.map(\.debugDescription).joined(separator: ", "))], errors: \(analysisErrors))"
	}
}
