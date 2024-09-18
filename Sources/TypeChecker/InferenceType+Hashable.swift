//
//  InferenceType+Hashable.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/18/24.
//

extension InferenceType: Hashable {
	public func hash(into hasher: inout Hasher) {
		hasher.combine(debugDescription)
	}
}
