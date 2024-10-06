//
//  BuiltinFunction.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import TalkTalkCore

public struct BuiltinFunction {
	public let name: String
	public let type: InferenceType

	public static var map: [String: BuiltinFunction] {
		[
			"print": .print,
			"_allocate": ._allocate,
			"_free": ._free,
			"_deref": ._deref,
			"_storePtr": ._storePtr,
			"_hash": ._hash,
			"_crash": ._crash
		]
	}

	public static var list: [BuiltinFunction] {
		[
			.print,
			._allocate,
			._free,
			._deref,
			._storePtr,
			._hash,
			._crash
		]
	}

	static func syntheticExpr() -> any Expr {
		IdentifierExprSyntax(id: -4, name: "__builtin__", location: [.synthetic(.builtin)])
	}

	public static var print: BuiltinFunction {
		BuiltinFunction(
			name: "print",
			type: .function(
				[
					.resolved(.any),
				],
				.resolved(.void)
			)
		)
	}

	public static var _allocate: BuiltinFunction {
		BuiltinFunction(
			name: "_allocate",
			type: .function(
				[.resolved(.base(.int))],
				.resolved(.base(.pointer))
			)
		)
	}

	public static var _free: BuiltinFunction {
		BuiltinFunction(
			name: "_free",
			type: .function(
				[.resolved(.base(.pointer))],
				.resolved(.void)
			)
		)
	}

	public static var _deref: BuiltinFunction {
		let returns = TypeVariable.new("_deref")

		return BuiltinFunction(
			name: "_deref",
			type: .function(
				[.resolved(.base(.pointer))],
				.resolved(.typeVar(returns))
			)
		)
	}

	public static var _storePtr: BuiltinFunction {
		BuiltinFunction(
			name: "_storePtr",
			type: .function(
				[
					.resolved(.base(.pointer)),
					.resolved(.any),
				],
				.resolved(.void)
			)
		)
	}

	public static var _hash: BuiltinFunction {
		BuiltinFunction(
			name: "_hash",
			type: .function(
				[.resolved(.any)],
				.resolved(.base(.int))
			)
		)
	}

	public static var _crash: BuiltinFunction {
		return BuiltinFunction(
			name: "_crash",
			type: .function(
				[
					.resolved(.base(.string)),
				],
				.resolved(.void)
			)
		)
	}

	public var parameters: [String] {
		guard case let .function(array, _) = type else {
			return []
		}

		return array.map(\.description)
	}
}
