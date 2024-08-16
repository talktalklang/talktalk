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

	// Try to find the most specific node that contains this position
	func nearestTo(line: Int, column: Int) -> any AnalyzedSyntax {
		var candidate: any AnalyzedSyntax = self

		for child in analyzedChildren {
			if child.location.range.count > candidate.location.range.count {
				candidate = child
			}
		}

		return candidate
	}

	var debugDescription: String {
		"\(Self.self)(analyzedChildren: [\(analyzedChildren.map(\.debugDescription).joined(separator: ", "))], errors: \(analysisErrors))"
	}
}
