//
//  Primitive.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

public enum Primitive: Byte, Sendable, Codable {
	case none, int, bool, byte, pointer, string
}
