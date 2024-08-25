//
//  Type.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

indirect enum InferenceType: Equatable {
	case variable(TypeVariable)
	case base(Primitive) // primitives
	case function([InferenceType], InferenceType)
	case void

	static func variable(_ name: String, _ id: VariableID) -> InferenceType {
		InferenceType.variable(TypeVariable(name, id))
	}
}
