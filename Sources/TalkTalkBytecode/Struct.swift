//
//  Struct.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/8/24.
//

public struct Struct: Equatable {
	public let name: String
	public let propertyCount: Int

	public init(name: String, propertyCount: Int) {
		self.name = name
		self.propertyCount = propertyCount
	}
}
