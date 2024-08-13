//
//  AnalysisError.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import TalkTalkSyntax

public enum AnalysisErrorKind: Equatable, Hashable {
	case argumentError(expected: Int, received: Int)
	case typeParameterError(expected: Int, received: Int)
	case typeNotFound(String)
	case unknownError(String)
}

public struct AnalysisError: Equatable, Hashable {
	public let kind: AnalysisErrorKind
	public let location: SourceLocation
}
