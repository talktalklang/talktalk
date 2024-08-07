//
//  DocumentDiagnosticReport.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

public struct DocumentDiagnosticReport: Encodable {
	public enum Kind: String, Encodable {
		case full, unchanged
	}

	let relatedDocuments: [String: FullDocumentDiagnosticReport]
}
