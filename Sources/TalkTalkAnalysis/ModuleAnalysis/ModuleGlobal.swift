//
//  ModuleGlobal.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax
import TalkTalkBytecode

public struct ModuleGlobal {
	public enum Source {
		case module, external(AnalysisModule)
	}

	public let name: String
	public let syntax: any Syntax
	public let type: ValueType
	public let source: Source

	public var isImport: Bool {
		if case .module = source {
			return false
		}

		return true
	}
}
