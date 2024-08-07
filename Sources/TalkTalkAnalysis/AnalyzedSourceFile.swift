//
//  AnalyzedSourceFile.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

public struct AnalyzedSourceFile {
	public let path: String
	public let syntax: [any AnalyzedSyntax]
}
