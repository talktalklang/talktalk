//
//  Environment+Capture.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax

public extension Environment {
	struct Capture: CustomStringConvertible {
		public static func any(_ name: String) -> Capture {
			Capture(
				name: name,
				binding: .init(
					name: name,
					expr: AnalyzedLiteralExpr(
						typeAnalyzed: .bool,
						expr: LiteralExprSyntax(value: .bool(true), location: [.synthetic(.true)]),
						environment: .init()
					),
					type: .bool
				),
				environment: .init()
			)
		}

		public let name: String
		public let binding: Binding
		public let environment: Environment

		public var description: String {
			".capture(\(name))"
		}
	}
}
