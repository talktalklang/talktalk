//
//  Definition.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

import TalkTalkSyntax

public struct Definition: @unchecked Sendable {
	public let token: Token
	public let type: InferenceType
}
