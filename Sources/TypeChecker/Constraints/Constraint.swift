//
//  Constraint.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/1/24.
//

import TalkTalkCore

protocol Constraint {
	var retries: Int { get set }
	var context: Context { get }

	func solve() throws

	var before: String { get }
	var after: String { get }
	var location: SourceLocation { get }
}
