//
//  AnalysisModule+FindSymbol.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//
import Foundation

public extension AnalysisModule {
	func findSymbol(line: Int, column: Int, path: String) -> (any AnalyzedSyntax)? {
		var candidate: (any AnalyzedSyntax)? = nil
		for file in analyzedFiles {
			if file.path != path {
				continue
			}

			for syntax in file.syntax {
				let match = syntax.nearestTo(line: line, column: column)

				if let currentCandidate = candidate, let match {
					if match.location.range.count < currentCandidate.location.range.count {
						candidate = match
					}
				} else {
					candidate = match
				}
			}
		}

		return candidate
	}
}
