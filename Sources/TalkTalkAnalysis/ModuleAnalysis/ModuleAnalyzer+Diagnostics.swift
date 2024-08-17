//
//  ModuleAnalyzer+Diagnostics.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/16/24.
//
import TalkTalkSyntax

public extension AnalysisModule {
	func collectErrors(for uri: String? = nil) throws -> Set<AnalysisError> {
		func collect(syntaxes: [any AnalyzedSyntax]) -> Set<AnalysisError> {
			var result: Set<AnalysisError> = []

			for syntax in syntaxes {
				if let err = syntax as? ParseError {
					// TODO: We wanna move away from this towards nodes just having their own errors
					result.insert(
						AnalysisError(kind: .unknownError(err.message), location: syntax.location)
					)
				}

				for error in syntax.analysisErrors {
					result.insert(error)
				}

				for error in collect(syntaxes: syntax.analyzedChildren) {
					result.insert(error)
				}
			}

			return result
		}

		var result: Set<AnalysisError> = []

		for file in analyzedFiles {
			if let uri, uri != file.path {
				continue
			}

			for err in collect(syntaxes: file.syntax) {
				result.insert(err)
			}
		}

		return result
	}
}
