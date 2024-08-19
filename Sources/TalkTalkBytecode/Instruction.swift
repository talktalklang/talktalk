//
//  Instruction.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Foundation

public protocol InstructionMetadata: CustomStringConvertible, Hashable {
	var length: Int { get }
	func emit(into chunk: inout Chunk, from instruction: Instruction)
}

public struct Instruction {
	public let line: UInt32
	public let offset: Int
	public let opcode: Opcode
	public let metadata: any InstructionMetadata

	public init(opcode: Opcode, offset: Int, line: UInt32, metadata: any InstructionMetadata) {
		self.line = line
		self.opcode = opcode
		self.offset = offset
		self.metadata = metadata
	}

	public func emit(into chunk: inout Chunk) {
		metadata.emit(into: &chunk, from: self)
	}

	public func dump() {
		FileHandle.standardError.write(Data((description + "\n").utf8))
	}
}

extension Instruction: CustomStringConvertible {
	public var description: String {
		let parts = [
			String(format: "%04d", offset),
			"\(line)",
			opcode.description,
			metadata.description,
		]

		return parts.joined(separator: " ")
	}
}

extension Instruction: Equatable {
	public static func == (lhs: Instruction, rhs: Instruction) -> Bool {
		lhs.line == rhs.line && lhs.opcode == rhs.opcode && lhs.metadata.hashValue == rhs.metadata.hashValue
	}
}

public extension InstructionMetadata where Self == SimpleMetadata {
	static var simple: SimpleMetadata { .init() }
}

public struct SimpleMetadata: InstructionMetadata {
	public init() {}

	public var length: Int = 1

	public var description: String {
		""
	}

	public func emit(into chunk: inout Chunk, from instruction: Instruction) {
		chunk.emit(opcode: instruction.opcode, line: instruction.line)
	}
}

public struct CaptureUpvalueMetadata: InstructionMetadata {
	public let slot: Byte
	public let name: String
	public var length = 2

	public func emit(into chunk: inout Chunk, from instruction: Instruction) {
		fatalError("TODO")
	}
	
	public var description: String {
		"slot: \(slot), name: \(name)"
	}
}

public struct ConstantMetadata: InstructionMetadata {
	public var value: Value

	public var length: Int = 2

	public init(value: Value) {
		self.value = value
	}

	public func emit(into chunk: inout Chunk, from instruction: Instruction) {
		chunk.emit(constant: value, line: instruction.line)
	}

	public var description: String {
		"\(value)"
	}
}

public struct ObjectMetadata: InstructionMetadata {
	public var value: StaticData

	public var length: Int = 2

	public init(value: StaticData) {
		self.value = value
	}

	public func emit(into chunk: inout Chunk, from instruction: Instruction) {
		chunk.emit(data: value, line: instruction.line)
	}

	public var description: String {
		"\(value)"
	}
}

public extension InstructionMetadata where Self == ConstantMetadata {
	static func constant(_ value: Value) -> ConstantMetadata {
		ConstantMetadata(value: value)
	}
}

public struct JumpMetadata: InstructionMetadata {
	let offset: Int
	public var length: Int = 3

	public func emit(into _: inout Chunk, from _: Instruction) {
		fatalError("TODO")
	}

	public var description: String {
		"offset: \(offset)"
	}
}

public extension InstructionMetadata where Self == JumpMetadata {
	static func jump(offset: Int) -> JumpMetadata {
		JumpMetadata(offset: offset)
	}
}

public struct LoopMetadata: InstructionMetadata {
	let back: Int
	public var length: Int = 3

	public func emit(into _: inout Chunk, from _: Instruction) {
		fatalError("TODO")
	}

	public var description: String {
		"to: \(back)"
	}
}

public extension InstructionMetadata where Self == LoopMetadata {
	static func loop(back: Int) -> LoopMetadata {
		LoopMetadata(back: back)
	}
}

public struct GetPropertyMetadata: InstructionMetadata {
	let slot: Int
	let options: PropertyOptions
	public var length: Int = 3

	public func emit(into _: inout Chunk, from _: Instruction) {
		fatalError("TODO")
	}

	public var description: String {
		"slot: \(slot), options: \(options)"
	}
}

public extension InstructionMetadata where Self == GetPropertyMetadata {
	static func getProperty(slot: Int, options: PropertyOptions) -> GetPropertyMetadata {
		GetPropertyMetadata(slot: slot, options: options)
	}
}

public struct PropertyMetadata: InstructionMetadata {
	public let slot: Int
	public let length = 2
	public func emit(into chunk: inout Chunk, from instruction: Instruction) {
		fatalError("TODO")
	}
	public var description: String {
		"property: \(slot)"
	}
}

public extension InstructionMetadata where Self == PropertyMetadata {
	static func property(slot: Int) -> PropertyMetadata {
		PropertyMetadata(slot: slot)
	}
}

public struct VariableMetadata: InstructionMetadata {
	public var length: Int = 3

	public let pointer: Pointer
	public let name: String

	public func emit(into _: inout Chunk, from _: Instruction) {
		fatalError("TODO")
	}

	public var description: String {
		"pointer: \(pointer), name: \(name)"
	}
}

public extension InstructionMetadata where Self == VariableMetadata {
	static func variable(_ pointer: Pointer, name: String = "") -> VariableMetadata {
		VariableMetadata(pointer: pointer, name: name)
	}

	static func global(slot: Int) -> VariableMetadata {
		VariableMetadata(pointer: .moduleValue(Byte(slot)), name: "")
	}

	static func stack(_ slot: Int, _ name: String) -> VariableMetadata {
		VariableMetadata(pointer: .stack(Byte(slot)), name: name)
	}

	static func heap(_ slot: Int, _ name: String) -> VariableMetadata {
		VariableMetadata(pointer: .heap(Byte(slot)), name: name)
	}
}

public struct ClosureMetadata: InstructionMetadata, CustomStringConvertible {
	let name: String?
	let arity: Byte
	let depth: Byte

	public var length: Int {
		2
	}

	public func emit(into _: inout Chunk, from _: Instruction) {
		fatalError("TODO")
	}

	public var description: String {
		var result = if let name { "name: \(name) " } else { "" }
		result += "arity: \(arity) depth: \(depth)"
		return result
	}
}

public extension InstructionMetadata where Self == ClosureMetadata {
	static func closure(name: String = "", arity: Byte, depth: Byte) -> ClosureMetadata {
		ClosureMetadata(name: name, arity: arity, depth: depth)
	}
}

public struct CallMetadata: InstructionMetadata {
	public let name: String
	public var length: Int = 1

	public func emit(into _: inout Chunk, from _: Instruction) {
		fatalError("TODO")
	}

	public var description: String {
		"name: \(name)"
	}
}

public extension InstructionMetadata where Self == CallMetadata {
	static func call(name: String) -> CallMetadata {
		CallMetadata(name: name)
	}
}
