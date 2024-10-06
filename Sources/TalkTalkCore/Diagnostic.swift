//
//  Diagnostic.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/27/24.
//

public struct Diagnostic: Equatable, Hashable {
	public enum Severity: Equatable {
		case error, warning, info
	}

	public let message: String
	public let severity: Severity
	public let location: SourceLocation
	public let subdiagnostics: [Diagnostic]

	public init(message: String, severity: Severity, subdiagnostics: [Diagnostic] = [], location: SourceLocation) {
		self.message = message
		self.severity = severity
		self.location = location
		self.subdiagnostics = subdiagnostics
	}
}
