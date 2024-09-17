//
//  LexicalScope.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax
import TypeChecker

public class LexicalScope {
	public var scope: any Instantiatable

	init(scope: any Instantiatable) {
		self.scope = scope
	}
}
