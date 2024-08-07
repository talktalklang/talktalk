//
//  UnchangedDocumentDiagnosticReport.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

public struct UnchangedDocumentDiagnosticReport: Encodable {
	let kind: DocumentDiagnosticReport.Kind = .unchanged
}
