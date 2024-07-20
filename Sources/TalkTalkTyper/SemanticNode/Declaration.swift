//
//  Declaration.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct Declaration: SemanticNode {
	public var type: any SemanticType = VoidType()
	public let syntax: any Decl
	public var binding: Binding
}
