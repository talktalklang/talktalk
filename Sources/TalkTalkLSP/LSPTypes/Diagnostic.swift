//
//  Diagnostic.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

public struct Diagnostic: Codable, Sendable, Hashable {
	// The range at which the message applies.
	public let range: Range

	/**
	 * The diagnostic's severity. To avoid interpretation mismatches when a
	 * server is used with different clients it is highly recommended that
	 * servers always provide a severity value. If omitted, it’s recommended
	 * for the client to interpret it as an Error severity.
	 */
	public let severity: Severity

	/**
	 * The diagnostic's message.
	 */
	public let message: String

	/**
	 * Additional metadata about the diagnostic.
	 *
	 * @since 3.15.0
	 */
	public let tags: [Tag]?

	/**
	 * An array of related diagnostic information, e.g. when symbol-names within
	 * a scope collide all definitions can be marked via this property.
	 */
	public let relatedInformation: RelatedInformation?

	public init(range: Range, severity: Severity, message: String, tags: [Tag]?, relatedInformation: RelatedInformation?) {
		self.range = range
		self.severity = severity
		self.message = message
		self.tags = tags
		self.relatedInformation = relatedInformation
	}
}

public extension Diagnostic {
	enum Severity: Int, Codable, Sendable {
		case error = 1, warning = 2, information = 3, hint = 4
	}

	enum Tag: Int, Codable, Sendable {
		case unnecessary = 1, deprecated = 2
	}

	struct RelatedInformation: Codable, Sendable, Hashable {
		public let location: Location
		public let message: String
	}
}
