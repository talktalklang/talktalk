//
//  Program.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct Program: SemanticNode {
	public var syntax: ProgramSyntax
	public var binding: Binding
	public var declarations: [Declaration]
	public var type: any SemanticType = VoidType()
}
