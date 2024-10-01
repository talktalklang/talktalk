//
//  Constraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/1/24.
//

protocol Constraint {
	var retries: Int { get set }
	var context: Context { get }

	func solve()

	var before: String { get }
	var after: String { get }
}
