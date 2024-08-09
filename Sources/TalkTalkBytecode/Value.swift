//
//  Value.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public final class Value: Equatable, Hashable, Codable {
	public static func == (lhs: Value, rhs: Value) -> Bool {
		lhs.storage == rhs.storage
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(storage)
	}

	private var storage: UInt64

	public var asUInt64: UInt64 {
		storage
	}

	// How many bits are we using to store tag data
	var tagSize = 4

	// Number of bits used for struct type ID
	var structTypeSize = 8

	// I think we can have a maximum of 16 tags total?
	enum Tag: UInt8 {
		case int = 0
		case bool = 1
		case pointer = 2
		case data = 3
		case none = 4
		case closure = 5
		case builtin = 6
		case moduleFunction = 7
		case `struct` = 8
		case instance = 9
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

	public static func closure(_ id: Byte) -> Value {
		Value(closureID: UInt64(id))
	}

	public static func pointer(_ addr: UInt64) -> Value {
		Value(pointer: addr)
	}

	public static func builtin(_ id: Byte) -> Value {
		Value(builtin: UInt64(id))
	}

	public static func moduleFunction(_ id: Byte) -> Value {
		Value(moduleFunction: UInt64(id))
	}

	public static func `struct`(_ id: Byte) -> Value {
		Value(struct: UInt64(id))
	}

	public static func instance(structType: UInt8, data: UInt64) -> Value {
		Value(instanceType: structType, data: data)
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
		storage |= (bool ? 1 : 0) &<< tagSize | UInt64(Tag.bool.rawValue)
	}

	public init(pointer: UInt64) {
		storage = 0
		storage |= (pointer &<< tagSize) | UInt64(Tag.pointer.rawValue)
	}

	public init(data: UInt64) {
		storage = 0
		storage |= (data &<< tagSize) | UInt64(Tag.data.rawValue)
	}

	public init(closureID: UInt64) {
		storage = 0
		storage |= (closureID &<< tagSize) | UInt64(Tag.closure.rawValue)
	}

	public init(builtin: UInt64) {
		storage = 0
		storage |= (builtin &<< tagSize) | UInt64(Tag.builtin.rawValue)
	}

	public init(moduleFunction: UInt64) {
		storage = 0
		storage |= (moduleFunction &<< tagSize) | UInt64(Tag.moduleFunction.rawValue)
	}

	public init(struct val: UInt64) {
		storage = 0
		storage |= (val &<< tagSize) | UInt64(Tag.struct.rawValue)
	}

	public init(instanceType: UInt8, data: UInt64) {
		storage = 0
		storage |= (UInt64(instanceType) &<< (tagSize + structTypeSize))
		storage |= (data &<< (tagSize + structTypeSize))
		storage |= UInt64(Tag.instance.rawValue)
	}

	public init() {
		storage = 0
		storage |= UInt64(Tag.none.rawValue)
	}

	public var isCallable: Bool {
		tag == .closure || tag == .builtin || tag == .moduleFunction || tag == .struct
	}

	public var intValue: Int64? {
		guard tag == .int else { return nil }
		return Int64(bitPattern: storage &>> tagSize)
	}

	public var boolValue: Bool? {
		guard tag == .bool else { return nil }
		return (storage &>> tagSize) != 0
	}

	public var pointerValue: UInt64? {
		guard tag == .pointer else { return nil }
		return storage &>> tagSize
	}

	public var dataValue: UInt64? {
		guard tag == .data else { return nil }
		return storage &>> tagSize
	}

	public var closureValue: UInt64? {
		guard tag == .closure else { return nil }
		return storage &>> tagSize
	}

	public var builtinValue: UInt64? {
		guard tag == .builtin else { return nil }
		return storage &>> tagSize
	}

	public var moduleFunctionValue: UInt64? {
		guard tag == .moduleFunction else { return nil }
		return storage &>> tagSize
	}

	public var structValue: UInt64? {
		guard tag == .struct else { return nil }
		return storage &>> tagSize
	}

	public var instanceStructType: UInt8? {
		guard tag == .instance else { return nil }
		return UInt8((storage &>> tagSize) & 0xFF)
	}

	public var instanceValue: UInt64? {
		guard tag == .instance else { return nil }
		return storage &>> (tagSize + structTypeSize)
	}

	public func disassemble(in chunk: Chunk) -> String {
		switch tag {
		case .closure:
			"closure(\(chunk.getChunk(at: Int(closureValue!)).name))"
		default:
			description
		}
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
		case .closure:
			"closure"
		case .builtin:
			"builtin"
		case .moduleFunction:
			"module function"
		case .struct:
			"struct"
		case .instance:
			"instance struct \(instanceValue as Any)"
		case .none:
			"none"
		}
	}
}
