//
//  Member.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/9/24.
//

import TalkTalkSyntax

public protocol Member {
	var name: String { get }
	var slot: Int { get }
	var inferenceType: InferenceType { get }
	var location: SourceLocation { get }
	var isMutable: Bool { get }
}
