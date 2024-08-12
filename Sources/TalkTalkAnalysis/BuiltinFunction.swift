//
//  Builtins.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public struct BuiltinFunction {
	public let name: String
	public let type: ValueType

	public static var list: [BuiltinFunction] {
		[
			.print,
		]
	}

	public static var print: BuiltinFunction {
		return BuiltinFunction(name: "print", type: .function("print", .int, [.init(name: "value", type: .any)], []))
	}
}
