//
//  Diagnostic.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkSyntax

public struct Diagnostic: Equatable, Hashable {
	enum Severity: Equatable {
		case error, warning, info
	}

	let message: String
	let severity: Severity
	let location: SourceLocation
}
