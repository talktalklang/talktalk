//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

indirect enum `Type` {
	case variable(Variable)
	case base(String) // primitives
	case function(Type, Type)
}
