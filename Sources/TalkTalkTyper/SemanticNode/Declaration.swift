//
//  Declaration.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct Declaration: SemanticNode {
	public let syntax: any Decl
	public var binding: Binding
	public var children: [any SemanticNode]
}
