//
//  Value.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public typealias Value = UInt64

let TAG_NONE: UInt64 = 1
let TAG_FALSE: UInt64 = 2
let TAG_TRUE: UInt64 = 3
let TAG_DATA: UInt64 = 4
let SIGN_BIT: UInt64 = 0x8000000000000000
let NAN: UInt64 = 0x7FFC000000000000

let NIL_VALUE = NAN | TAG_NONE
let TRUE_VALUE = NAN | TAG_TRUE
let FALSE_VALUE = NAN | TAG_FALSE

public extension Value {
	enum Casted: Equatable {
		case int(Int64),
		     bool(Bool),
		     data(UInt32),
		     none
	}

	static func int(_ int: Int64) -> Value {
		Value(bitPattern: int)
	}

	static func bool(_ bool: Bool) -> Value {
		bool ? TRUE_VALUE : FALSE_VALUE
	}

	static func data(_ offset: Int32) -> Value {
		let intBits = UInt32(bitPattern: offset) & 0xFFFFFFFF
		return Value(intBits) | UInt32(NAN | TAG_DATA)
	}

	static var none: Value {
		Value(NAN | TAG_NONE)
	}

	var result: Casted {
		if isBool {
			return .bool(self == TRUE_VALUE)
		}

		if isData {
			return .data(asData)
		}

		if isInt {
			return .int(Int64(bitPattern: self))
		}

		return .none
	}

	var isBool: Bool {
		self | 1 == TRUE_VALUE
	}

	var asBool: Bool {
		self == TRUE_VALUE
	}

	var isInt: Bool {
		self & NAN != NAN
	}

	var asInt: Int64 {
		Int64(bitPattern: self)
	}

	var isData: Bool {
		self & NAN == 0 && (self & 0xFF == TAG_DATA)
	}

	var asData: UInt32 {
		UInt32(bitPattern: Int32(self & ~UInt64(NAN | TAG_DATA)))
	}
}

public extension Value {
	var bits: [UInt8] {
		(0 ..< 64).map { (self >> (63 - $0)) & 1 }.map { UInt8($0) }
	}
}
