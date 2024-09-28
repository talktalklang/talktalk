//
//  ModuleAnalyzer+Diagnostics.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/16/24.
//
import TalkTalkCore

public extension AnalysisModule {
	struct ErrorResults {
		public var file: Set<AnalysisError>
		public var all: Set<AnalysisError>

		public var isEmpty: Bool {
			all.isEmpty
		}

		public var count: Int {
			all.count
		}
	}

	func collectErrors(for uri: String? = nil) throws -> ErrorResults {
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

		var result = ErrorResults(file: [], all: [])

		for file in analyzedFiles {
			for err in collect(syntaxes: file.syntax) {
				result.all.insert(err)

				if let uri, uri != file.path {
					continue
				}

				result.file.insert(err)
			}
		}

		return result
	}
}
