//
//  AnalysisError.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/22/24.
//

import TalkTalkAnalysis

public extension AnalysisError {
	func diagnostic() -> Diagnostic {
		let start = location.start
		let end = location.end

		return Diagnostic(
			range: Range(
				start: Position(line: start.line, character: start.column),
				end: Position(line: end.line, character: end.column)
			),
			severity: .error,
			message: message,
			tags: nil,
			relatedInformation: nil
		)
	}
}
