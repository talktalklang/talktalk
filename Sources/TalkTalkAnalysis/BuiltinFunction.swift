//
//  Builtins.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import TalkTalkSyntax

public struct BuiltinFunction {
	public let name: String
	public let type: ValueType

	public static var list: [BuiltinFunction] {
		[
			.print,
			.allocate,
			.free,
		]
	}

	static func syntheticExpr() -> any Expr {
		IdentifierExprSyntax(name: "__builtin__", location: [.synthetic(.builtin)])
	}

	func binding() -> Environment.Binding {
		.init(
			name: name,
			expr: Self.syntheticExpr(),
			type: type,
			isCaptured: false,
			isBuiltin: true,
			isParameter: false,
			isGlobal: false,
			externalModule: nil
		)

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
