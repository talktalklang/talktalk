//
//  BuiltinStruct.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

import TalkTalkBytecode

// Builtin properties are able to be accessed on a struct instance
struct BuiltinStructProperty {
	var name: String
	var instanceSlot: Int
}

// Builtin methods are looked up using basically the same mechanism as
// non-builtins, but instead of evaluating a chunk, they get passed the
// StructInstance to their `call` block and return a value.
struct BuiltinStructMethod {
	var name: String
	var call: (_ receiver: StructInstance, _ methodSlot: Int, _ args: [Value]) -> Value
}

protocol BuiltinStruct {
	static func instantiate() -> Self

	func getProperty(_ slot: Int) -> Value
	func call(_ slot: Int, _ args: [Value]) -> Value?
	func arity(for methodSlot: Int) -> Int
}

enum BuiltinStructs {
	static var list: [any BuiltinStruct.Type] {
		[
		]
	}
}
