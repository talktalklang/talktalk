//
//  Error.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public struct Error: Swift.Error {
	public let token: Token
	public let message: String
}
