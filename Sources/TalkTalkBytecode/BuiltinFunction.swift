//
//  BuiltinFunction.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/7/24.
//

public enum BuiltinFunction: Byte, Sendable, Codable {
	case print, _allocate, _free, _deref, _storePtr
}
