//
//  AnalyzedVarLetDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/17/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

public protocol AnalyzedVarLetDecl: AnalyzedDecl, VarLetDecl {
	var symbol: Symbol? { get }
	var valueAnalyzed: (any AnalyzedExpr)? { get }
}
