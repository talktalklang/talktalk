//
//  Syntax+Consumable.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
protocol Consumable {
	static func consuming(_ token: Token) -> Self?
}
