//
//  Binding.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

import TalkTalkSyntax

public extension Environment {
	class Binding {
		public let name: String
		public var expr: any Syntax
		public var type: ValueType
		public var isCaptured: Bool
		public var isBuiltin: Bool
		public var isParameter: Bool
		public var isGlobal: Bool

		public init(
			name: String,
			expr: any Syntax,
			type: ValueType,
			isCaptured: Bool = false,
			isBuiltin: Bool = false,
			isParameter: Bool = false,
			isGlobal: Bool = false
		) {
			self.name = name
			self.expr = expr
			self.type = type
			self.isCaptured = isCaptured
			self.isBuiltin = isBuiltin
			self.isParameter = isParameter
			self.isGlobal = isGlobal
		}
	}
}
