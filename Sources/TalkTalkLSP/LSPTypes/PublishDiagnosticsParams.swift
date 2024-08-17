//
//  PublishDiagnosticsParams.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

public struct PublishDiagnosticsParams: Codable, Sendable {
	public let uri: String
	public let diagnostics: [Diagnostic]
}
