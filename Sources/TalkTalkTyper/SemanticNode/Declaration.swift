//
//  Declaration.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public protocol Declaration: SemanticNode {
	var type: any SemanticType { get set }
	var syntax: any Syntax { get }
	var scope: Scope { get }
}
