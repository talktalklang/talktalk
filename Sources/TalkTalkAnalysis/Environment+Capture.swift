//
//  Environment+Capture.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkCore
import TypeChecker

public extension Environment {
	struct Capture: CustomStringConvertible {
		public static func any(_ name: String, context: Context) -> Capture {
			Capture(
				name: name,
				binding: .init(
					name: name,
					location: [.synthetic(.true)],
					type: InferenceType.base(.bool)
				),
				environment: .init(inferenceContext: context, symbolGenerator: .init(moduleName: "", parent: nil))
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
