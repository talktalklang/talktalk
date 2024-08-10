//
//  FullDocumentDiagnosticReport.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

public struct FullDocumentDiagnosticReport: Codable {
	public let kind: DocumentDiagnosticReport.Kind = .full
	public let items: [Diagnostic]
}
