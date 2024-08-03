//
//  Instruction.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Foundation

public protocol InstructionMetadata: CustomStringConvertible, Hashable {
	func emit(into chunk: inout Chunk, from instruction: Instruction)
}

public struct Instruction {
	public let line: UInt32
	public let offset: Int
	public let opcode: Opcode
	public let metadata: any InstructionMetadata

	public init(opcode: Opcode, line: UInt32, offset: Int, metadata: any InstructionMetadata) {
		self.line = line
		self.opcode = opcode
		self.offset = offset
		self.metadata = metadata
	}

	public func emit(into chunk: inout Chunk) {
		metadata.emit(into: &chunk, from: self)
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

	public var description: String {
		""
	}

	public func emit(into chunk: inout Chunk, from instruction: Instruction) {
		chunk.emit(opcode: instruction.opcode, line: instruction.line)
	}
}

public struct ConstantMetadata: InstructionMetadata {
	public var value: Value

	public init(value: Value) {
		self.value = value
	}

	public func emit(into chunk: inout Chunk, from instruction: Instruction) {
		chunk.emit(constant: value, line: instruction.line)
	}

	public var description: String {
		"\(value.result)"
	}
}

public struct ObjectMetadata: InstructionMetadata {
	public var object: Object

	public init(object: Object) {
		self.object = object
	}

	public func emit(into chunk: inout Chunk, from instruction: Instruction) {
		chunk.emit(data: object.bytes, line: instruction.line)
	}

	public var description: String {
		"\(object)"
	}
}

public extension InstructionMetadata where Self == ConstantMetadata {
	static func constant(_ value: Value) -> ConstantMetadata {
		ConstantMetadata(value: value)
	}
}
