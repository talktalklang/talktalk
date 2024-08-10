//
//  DocumentDiagnosticReport.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

public struct DocumentDiagnosticReport: Codable {
	public enum Kind: String, Codable {
		case full, unchanged
	}

	let relatedDocuments: [String: FullDocumentDiagnosticReport]
}
