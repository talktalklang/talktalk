//
//  Scheme.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

struct Scheme: Equatable {
	let variables: [TypeVariable]
	let type: InferenceType
}
