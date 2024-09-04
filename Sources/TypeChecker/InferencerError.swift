//
//  InferencerError.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/3/24.
//

public enum InferencerError: Error {
	case typeNotInferred(String)
	case cannotInfer(String)
}
