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
	func nearestTo(line: Int, column: Int, candidate: (any AnalyzedSyntax)? = nil) -> any AnalyzedSyntax {
		var candidate: any AnalyzedSyntax = candidate ?? self

		if location.range.count < candidate.location.range.count,
			 location.contains(line: line, column: column) {
			candidate = self
		}

		for child in analyzedChildren {
			candidate = child.nearestTo(line: line, column: column, candidate: candidate)
		}

		return candidate
	}

	func definition() -> Definition? {
		switch self {
		case let node as AnalyzedMemberExpr:
			return node.definition()
		case let node as AnalyzedVarExpr:
			return node.definition()
		default: ()
		}

		return nil
	}

	var debugDescription: String {
		"\(Self.self)(analyzedChildren: [\(analyzedChildren.map(\.debugDescription).joined(separator: ", "))], errors: \(analysisErrors))"
	}
}
