//
//  Diagnostic.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

import TalkTalkSyntax

struct Diagnostic: Equatable {
	enum Severity: Equatable {
		case error, warning, info
	}

	let message: String
	let severity: Severity
	let location: SourceLocation
}
