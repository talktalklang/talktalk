//
//  Function.swift
//  
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct Function: SemanticNode {
	public var syntax: FunctionDeclSyntax
	public var binding: Binding
}
