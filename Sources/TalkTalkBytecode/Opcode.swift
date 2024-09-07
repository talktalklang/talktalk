//
//  Opcode.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public enum Opcode: Byte {
	public var byte: Byte { rawValue }

	case `return`,
	     constant,
	     negate,
	     not,

	     // Callables
	     call, callChunkID,

	     // Stack operations
	     pop,

	     // Functions
	     defClosure,

	     // Local variables
	     setLocal,
	     getLocal,

	     // Upvalues (captures)
	     getUpvalue, setUpvalue,

	     // Module functions
	     getModuleFunction, setModuleFunction,

	     // Module global values
	     getModuleValue, setModuleValue,

	     // Structs
	     getStruct, setStruct,
	     getProperty, setProperty,

	     // Type casting
	     cast, `is`, primitive,

	     // Builtins
	     getBuiltin, setBuiltin,
	     getBuiltinStruct, setBuiltinStruct,

			 // Dictionaries
			 initDict,

			 // Arrays
			 initArray, get,

	     // Literals
	     `true`,
	     `false`,
	     none,

	     // Static data
	     data,

	     // Suspension
	     suspend,

	     // Equality
	     equal,
	     notEqual,

	     // Jumps
	     jump,
	     jumpUnless,
	     jumpPlaceholder,
	     loop,

			 // Pattern matching
			 matchBegin,
			 matchCase,
			 matchEnd,

			 // Enum stuff
			 getEnumCase,

	     // Comparisons
	     less,
	     greater,
	     lessEqual,
	     greaterEqual,

	     // Binary operations
	     add,
	     subtract,
	     divide,
	     multiply
}

extension Opcode {
	public var description: String {
		"OP_\(format())"
	}

	func format() -> String {
		"\(self)"
			.replacing(#/([a-z])([A-Z])/#, with: { "\($0.output.1)_\($0.output.2)" })
			.uppercased()
	}
}
