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
	public let path: String
	public let line: UInt32
	public let offset: Int
	public let opcode: Opcode
	public let metadata: any InstructionMetadata

	public init(path: String, opcode: Opcode, offset: Int, line: UInt32, metadata: any InstructionMetadata) {
		self.path = path
		self.line = line
		self.opcode = opcode
		self.offset = offset
		self.metadata = metadata
	}

	public func emit(into chunk: inout Chunk) {
		metadata.emit(into: &chunk, from: self)
	}

	public func dump() {
		print(description)
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

public struct FunctionMetadata: InstructionMetadata {
	let name: String

	public init(name: String) {
		self.name = name
	}

	public var length: Int = 1

	public var description: String {
		"name: \(name)"
	}

	public func emit(into chunk: inout Chunk, from instruction: Instruction) {
		chunk.emit(opcode: instruction.opcode, line: instruction.line)
	}
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

public struct InitArrayMetadata: InstructionMetadata {
	public var elementCount: Int

	public var length: Int {
		elementCount + 2
	}

	public func emit(into chunk: inout Chunk, from instruction: Instruction) {
		fatalError("TODO")
	}
	
	public var description: String {
		"Array (\(elementCount))"
	}
}

public extension InstructionMetadata where Self == InitArrayMetadata {
	static func array(count: Int) -> InitArrayMetadata {
		InitArrayMetadata(elementCount: count)
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

public struct VariableMetadata: InstructionMetadata {
	public enum VariableType {
		case local, global, builtin, `struct`, property, moduleFunction
	}

	public var length: Int = 2

	public let slot: Byte
	public let name: String
	public let type: VariableType

	public func emit(into _: inout Chunk, from _: Instruction) {
		fatalError("TODO")
	}

	public var description: String {
		"slot: \(slot), name: \(name)"
	}
}

public extension InstructionMetadata where Self == VariableMetadata {
	static func local(slot: Byte, name: String) -> VariableMetadata {
		VariableMetadata(slot: slot, name: name, type: .local)
	}

	static func global(slot: Byte) -> VariableMetadata {
		VariableMetadata(slot: slot, name: "slot: \(slot)", type: .global)
	}

	static func builtin(slot: Byte, name: String) -> VariableMetadata {
		VariableMetadata(slot: slot, name: name, type: .builtin)
	}

	static func `struct`(slot: Byte) -> VariableMetadata {
		VariableMetadata(slot: slot, name: "slot: \(slot)", type: .struct)
	}

	static func property(slot: Byte) -> VariableMetadata {
		VariableMetadata(slot: slot, name: "slot: \(slot)", type: .property)
	}
}

public struct ClosureMetadata: InstructionMetadata, CustomStringConvertible {
	public struct Upvalue: Equatable, Hashable {
		public static func == (lhs: Upvalue, rhs: Upvalue) -> Bool {
			lhs.isLocal == rhs.isLocal && lhs.index == rhs.index
		}

		var isLocal: Bool
		var index: Byte

		public static func capturing(_ index: Byte) -> Upvalue {
			Upvalue(isLocal: true, index: index)
		}

		public static func inherited(_ index: Byte) -> Upvalue {
			Upvalue(isLocal: false, index: index)
		}

		public var description: String {
			"isLocal: \(isLocal) i: \(index)"
		}
	}

	let name: String?
	let arity: Byte
	let depth: Byte
	let upvalues: [Upvalue]
	public var length: Int {
		2 + (upvalues.count * 2)
	}

	public func emit(into _: inout Chunk, from _: Instruction) {
		fatalError("TODO")
	}

	public var description: String {
		var result = if let name { "name: \(name) " } else { "" }
		result += "arity: \(arity) depth: \(depth) upvalues: [\(upvalues.map(\.description).joined(separator: ", "))]"
		return result
	}
}

public extension InstructionMetadata where Self == ClosureMetadata {
	static func closure(name: String? = nil, arity: Byte, depth: Byte, upvalues: [ClosureMetadata.Upvalue] = []) -> ClosureMetadata {
		ClosureMetadata(name: name, arity: arity, depth: depth, upvalues: upvalues)
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

public struct UpvalueMetadata: InstructionMetadata {
	public let slot: Byte
	public let name: String
	public var length: Int = 2

	public func emit(into _: inout Chunk, from _: Instruction) {
		fatalError("TODO")
	}

	public var description: String {
		"local: \(slot), name: \(name)"
	}
}

public extension InstructionMetadata where Self == UpvalueMetadata {
	static func upvalue(slot: Byte, name: String) -> UpvalueMetadata {
		UpvalueMetadata(slot: slot, name: name)
	}
}
