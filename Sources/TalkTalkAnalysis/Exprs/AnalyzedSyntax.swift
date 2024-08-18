//
//  AnalyzedSyntax.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkSyntax

public protocol AnalyzedSyntax: Syntax, CustomDebugStringConvertible {
	var typeID: TypeID { get }
	var analyzedChildren: [any AnalyzedSyntax] { get }
	var analysisErrors: [AnalysisError] { get }
	var environment: Environment { get }

	func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor
}

public extension AnalyzedSyntax {
	var typeAnalyzed: ValueType {
		typeID.current
	}

	var analysisErrors: [AnalysisError] { [] }

	func collectErrors() -> [AnalysisError] {
		var result = analysisErrors
		for child in analyzedChildren {
			result.append(contentsOf: child.collectErrors())
		}
		return result
	}

	// Try to find the most specific node that contains this position
	func nearestTo(line: Int, column: Int, candidate: (any AnalyzedSyntax)? = nil) -> (any AnalyzedSyntax)? {
		var candidate: any AnalyzedSyntax = candidate ?? self

		if location.range.count < candidate.location.range.count,
		   location.contains(line: line, column: column)
		{
			candidate = self
		}

		for child in analyzedChildren {
			if let newCandidate = child.nearestTo(line: line, column: column, candidate: candidate) {
				candidate = newCandidate
			}
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
		if analysisErrors.isEmpty {
			"\(Self.self)(ln: \(location.line), type: \(typeID.current.description))"
		} else {
			"\(Self.self)(lns: \(location.line), type: \(typeID.current.description), errors: \(analysisErrors))"
		}
	}
}
