//
//  BuiltinFunction.swift
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
			._allocate,
			._free,
			._deref,
			._storePtr,
			._hash,
			._cast
		]
	}

	static func syntheticExpr() -> any Expr {
		IdentifierExprSyntax(id: -4, name: "__builtin__", location: [.synthetic(.builtin)])
	}

	func binding(in _: Environment) -> Environment.Binding {
		.init(
			name: name,
			expr: Self.syntheticExpr(),
			type: TypeID(type),
			isCaptured: false,
			isBuiltin: true,
			isParameter: false,
			isGlobal: false,
			externalModule: nil
		)
	}

	public static var print: BuiltinFunction {
		BuiltinFunction(
			name: "print",
			type: .function(
				"print",
				TypeID(.int),
				[
					.init(
						name: "value",
						typeID: TypeID(.any)
					),
				],
				[]
			)
		)
	}

	public static var _allocate: BuiltinFunction {
		BuiltinFunction(
			name: "_allocate",
			type: .function("_allocate", TypeID(.pointer, immutable: true), [.int("size")], [])
		)
	}

	public static var _free: BuiltinFunction {
		BuiltinFunction(
			name: "_free",
			type: .function(
				"_free",
				TypeID(.void),
				[.init(
					name: "addr",
					typeID: TypeID(.pointer)
				)],
				[]
			)
		)
	}

	public static var _deref: BuiltinFunction {
		BuiltinFunction(
			name: "_deref",
			type: .function(
				"_deref",
				TypeID(.placeholder),
				[.init(
					name: "addr",
					typeID: TypeID(.pointer)
				)],
				[]
			)
		)
	}

	public static var _storePtr: BuiltinFunction {
		BuiltinFunction(
			name: "_storePtr",
			type: .function(
				"_storePtr",
				TypeID(.placeholder),
				[.init(name: "addr", typeID: TypeID(.pointer)),
				 .init(name: "value", typeID: TypeID())],
				[]
			)
		)
	}

	public static var _hash: BuiltinFunction {
		BuiltinFunction(
			name: "_hash",
			type: .function(
				"_hash",
				TypeID(.int),
				[.init(name: "value", typeID: TypeID(.any))],
				[]
			)
		)
	}

	public static var _cast: BuiltinFunction {
		BuiltinFunction(
			name: "_cast",
			type: .function(
				"_cast",
				TypeID(.generic(.void, "T")),
				[
					.init(name: "variable", typeID: TypeID(.any)),
					.init(name: "type", typeID: TypeID(.generic(.void, "T")))
				],
				[]
			)
		)
	}
}
