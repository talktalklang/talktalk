//
//  InferenceResult.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

enum InferenceResult: Equatable {
	case scheme(Scheme), type(InferenceType)
}
