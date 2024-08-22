//
//  Method.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/9/24.
//

import TalkTalkBytecode
import TalkTalkSyntax

public struct SerializedMethod: Codable {
	public let symbol: Symbol
	public let name: String
	public let params: [String]
	public let type: ValueType
	public let isMutable: Bool
}

public struct Method: Member {
	public let symbol: Symbol
	public let name: String
	public let params: [ValueType.Param]
	public let typeID: TypeID
	public let returnTypeID: TypeID
	public let expr: any Syntax
	public let isMutable: Bool
	public let isSynthetic: Bool

	public init(
		symbol: Symbol,
		name: String,
		params: [ValueType.Param],
		typeID: TypeID,
		returnTypeID: TypeID,
		expr: any Syntax,
		isMutable: Bool = false,
		isSynthetic: Bool = false
	) {
		self.symbol = symbol
		self.name = name
		self.params = params
		self.typeID = typeID
		self.returnTypeID = returnTypeID
		self.expr = expr
		self.isMutable = isMutable
		self.isSynthetic = isSynthetic
	}
}
