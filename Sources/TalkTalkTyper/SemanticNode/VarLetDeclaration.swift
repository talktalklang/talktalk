//
//  VarLetDeclaration.swift
//  
//
//  Created by Pat Nakajima on 7/20/24.
//

import TalkTalkSyntax

public struct VarLetDeclaration: Declaration {
	public var type: any SemanticType
	public var syntax: any Decl
	public var scope: Scope

	// If a variable is used as a return then we can try to update
	// it using return type info we might have
	public var isUsedAsReturn: Bool = false
}
