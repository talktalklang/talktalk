//
//  AnalyzedVarLetDecl.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/17/24.
//

import TalkTalkSyntax

public protocol AnalyzedVarLetDecl: AnalyzedDecl, VarLetDecl {
	var valueAnalyzed: (any AnalyzedExpr)? { get }
}
