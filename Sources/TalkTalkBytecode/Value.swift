//
//  Value.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public struct Value: Equatable, Hashable {
	private var storage: UInt64

	enum Tag: UInt8 {
		case int = 0
		case bool = 1
		case pointer = 2
		case data = 3
		case none = 4
	}

	public static var none: Value {
		Value()
	}

	public static func int(_ int: Int64) -> Value {
		Value(int: int)
	}

	public static func bool(_ bool: Bool) -> Value {
		Value(bool: bool)
	}

	public static func data(_ offset: UInt64) -> Value {
		Value(data: offset)
	}

	var tag: Tag {
		return Tag(rawValue: UInt8(storage & 0xF))!
	}

	public init(int: Int64) {
		storage = 0
		storage |= (UInt64(bitPattern: int) &<< 4) | UInt64(Tag.int.rawValue)
	}

	public init(bool: Bool) {
		storage = 0
		storage |= (bool ? 1 : 0) &<< 4 | UInt64(Tag.bool.rawValue)
	}

	public init(pointer: UInt64) {
		storage = 0
		storage |= (pointer &<< 4) | UInt64(Tag.pointer.rawValue)
	}

	public init(data: UInt64) {
		storage = 0
		storage |= (data &<< 4) | UInt64(Tag.data.rawValue)
	}

	public init() {
		storage = 0
		storage |= UInt64(Tag.none.rawValue)
	}

	public var intValue: Int64? {
		guard tag == .int else { return nil }
		return Int64(bitPattern: storage &>> 4)
	}

	public var boolValue: Bool? {
		guard tag == .bool else { return nil }
		return (storage &>> 4) != 0
	}

	public var pointerValue: UInt64? {
		guard tag == .pointer else { return nil }
		return storage &>> 4
	}

	public var dataValue: UInt64? {
		guard tag == .data else { return nil }
		return storage &>> 4
	}
}

public extension Value {
	var bits: [UInt8] {
		(0 ..< 64).map { (storage >> (63 - $0)) & 1 }.map { UInt8($0) }
	}
}

extension Value: CustomStringConvertible {
	public var description: String {
		switch tag {
		case .int:
			".int(\(intValue!))"
		case .bool:
			".bool(\(boolValue!))"
		case .pointer:
			".pointer(\(pointerValue!))"
		case .data:
			".data(\(dataValue!))"
		case .none:
			"none"
		}
	}
}
