//
//  Constraints+Builtin.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

extension Constraints {
	func setupBuiltin() {
		// ints can have arithmetic, as a treat
		addConstraints(
			to: .base(.int),
			[
				.infixOperator(.plus, rhs: [.base(.int)], returns: .base(.int)),
				.infixOperator(.minus, rhs: [.base(.int)], returns: .base(.int)),
				.infixOperator(.star, rhs: [.base(.int)], returns: .base(.int)),
				.infixOperator(.slash, rhs: [.base(.int)], returns: .base(.int)),
			]
		)

		addConstraints(
			to: .base(.string),
			[
				.infixOperator(.plus, rhs: [.base(.string)], returns: .base(.string)),
			]
		)
	}
}
