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
		public var definition: (any Syntax)?
		public var type: TypeID
		public var isCaptured: Bool
		public var isBuiltin: Bool
		public var isParameter: Bool
		public var isGlobal: Bool
		public var isMutable: Bool
		public var externalModule: AnalysisModule?

		public init(
			name: String,
			expr: any Syntax,
			definition: (any Syntax)? = nil,
			type: TypeID,
			isCaptured: Bool = false,
			isBuiltin: Bool = false,
			isParameter: Bool = false,
			isGlobal: Bool = false,
			isMutable: Bool = false,
			externalModule: AnalysisModule? = nil
		) {
			self.name = name
			self.expr = expr
			self.definition = definition
			self.type = type
			self.isCaptured = isCaptured
			self.isBuiltin = isBuiltin
			self.isParameter = isParameter
			self.isGlobal = isGlobal
			self.isMutable = isMutable
			self.externalModule = externalModule
		}
	}
}
