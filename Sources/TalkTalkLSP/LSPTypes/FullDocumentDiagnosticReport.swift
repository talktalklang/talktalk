//
//  FullDocumentDiagnosticReport.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

public struct FullDocumentDiagnosticReport: Codable {
	enum CodingKeys: CodingKey {
		case kind, items
	}

	public let kind: DocumentDiagnosticReport.Kind = .full
	public let items: [Diagnostic]
}
