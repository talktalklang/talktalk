//
//  AnalysisModule+FindSymbol.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

public extension AnalysisModule {
	func findSymbol(line: Int, column: Int, path: String) -> (any AnalyzedSyntax)? {
		var candidate: (any AnalyzedSyntax)? = nil
		for file in analyzedFiles {
			if file.path.components(separatedBy: "/").last != path.components(separatedBy: "/").last {
				continue
			}

			for syntax in file.syntax {
				guard syntax.location.contains(line: line, column: column) else {
					continue
				}

				let match = syntax.nearestTo(line: line, column: column)

				if let currentCandidate = candidate {
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
