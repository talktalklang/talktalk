//
//  Error.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct Error: Swift.Error {
	let token: Token
	let message: String
}
