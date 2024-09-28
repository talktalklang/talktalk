//
//  Definition.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/15/24.
//

import TalkTalkCore

public struct Definition: @unchecked Sendable {
	public let location: SourceLocation
	public let type: InferenceType
}
