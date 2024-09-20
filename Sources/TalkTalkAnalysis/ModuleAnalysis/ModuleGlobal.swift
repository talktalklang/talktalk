//
//  ModuleGlobal.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//
import TalkTalkSyntax
import TalkTalkBytecode

public enum ModuleSource {
	case module, external(AnalysisModule)
}

public protocol ModuleGlobal {
	var name: String { get }
	var symbol: Symbol { get }
	var location: SourceLocation { get }
	var typeID: InferenceType { get }
	var source: ModuleSource { get }
}
