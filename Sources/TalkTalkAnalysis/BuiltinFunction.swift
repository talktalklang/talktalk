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
			.allocate,
			.free
		]
	}

	public static var print: BuiltinFunction {
		return BuiltinFunction(
			name: "print",
			type: .function(
				"print", .int, [.init(name: "value", type: .any)],
				[])
		)
	}

	public static var allocate: BuiltinFunction {
		return BuiltinFunction(
			name: "allocate",
			type: .function("allocate", .pointer, [.int("size")], [])
		)
	}

	public static var free: BuiltinFunction {
		return BuiltinFunction(
			name: "free",
			type: .function("free", .void, [.init(name: "addr", type: .pointer)], [])
		)
	}

}
