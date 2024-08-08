//
//  Builtins.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public struct Builtin {
	public let name: String
	public let type: ValueType

	public static var list: [Builtin] {
		[
			.print
		]
	}

	public static var print: Builtin {
		return Builtin(name: "print", type: .function("print", .int, [.int("value")], []))
	}
}
