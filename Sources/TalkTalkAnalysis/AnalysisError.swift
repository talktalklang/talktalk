//
//  AnalysisError.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/10/24.
//

import TalkTalkSyntax

public enum AnalysisErrorKind: Equatable {
	case argumentError(expected: Int, received: Int)
}

public struct AnalysisError: Equatable {
	public let kind: AnalysisErrorKind
	public let location: SourceLocation
}
