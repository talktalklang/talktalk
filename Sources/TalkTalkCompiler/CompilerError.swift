//
//  CompilerError.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/3/24.
//

import TalkTalkAnalysis

public enum CompilerError: Error {
	case unknownIdentifier(String), analysisError(String), analysisErrors(String)
}
