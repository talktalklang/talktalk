//
//  Instruction.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Foundation

public protocol InstructionMetadata: CustomStringConvertible, Hashable {
	var length: Int { get }
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
}

public struct SimpleMetadata: InstructionMetadata {
	public init() {}

	public var length: Int = 1

	public var description: String {
		""
	}
}

public struct ConstantMetadata: InstructionMetadata {
	public var value: Value

	public var length: Int = 2

	public init(value: Value) {
		self.value = value
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
	let symbol: Symbol
	let options: PropertyOptions
	public var length: Int = 3

	public var description: String {
		"symbol: \(symbol), options: \(options)"
	}
}

public extension InstructionMetadata where Self == GetPropertyMetadata {
	static func getProperty(_ symbol: Symbol, options: PropertyOptions) -> GetPropertyMetadata {
		GetPropertyMetadata(symbol: symbol, options: options)
	}
}

public struct VariableMetadata: InstructionMetadata {
	public enum VariableType {
		case local, global, builtin, `struct`, property, moduleFunction
	}

	public var length: Int = 2

	public let symbol: Symbol
	public let type: VariableType

	public var description: String {
		"symbol: \(symbol), type: \(type)"
	}
}

public extension InstructionMetadata where Self == VariableMetadata {
	static func local(_ symbol: Symbol) -> VariableMetadata {
		VariableMetadata(symbol: symbol, type: .local)
	}

	static func global(_ symbol: Symbol) -> VariableMetadata {
		VariableMetadata(symbol: symbol, type: .global)
	}

	static func builtin(_ symbol: Symbol) -> VariableMetadata {
		VariableMetadata(symbol: symbol, type: .builtin)
	}

	static func `struct`(_ symbol: Symbol) -> VariableMetadata {
		VariableMetadata(symbol: symbol, type: .struct)
	}

	static func property(_ symbol: Symbol) -> VariableMetadata {
		VariableMetadata(symbol: symbol, type: .property)
	}

	static func moduleFunction(_ symbol: Symbol) -> VariableMetadata {
		VariableMetadata(symbol: symbol, type: .moduleFunction)
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
	public var length: Int {
		2
	}

	public var description: String {
		var result = if let name { "name: \(name) " } else { "" }
		result += "arity: \(arity) depth: \(depth)"
		return result
	}
}

public extension InstructionMetadata where Self == ClosureMetadata {
	static func closure(name: String? = nil, arity: Byte, depth: Byte, upvalues: [ClosureMetadata.Upvalue] = []) -> ClosureMetadata {
		ClosureMetadata(name: name, arity: arity, depth: depth)
	}
}

public struct CallMetadata: InstructionMetadata {
	public let name: String
	public var length: Int = 1

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

	public var description: String {
		"local: \(slot), name: \(name)"
	}
}

public extension InstructionMetadata where Self == UpvalueMetadata {
	static func upvalue(slot: Byte, name: String) -> UpvalueMetadata {
		UpvalueMetadata(slot: slot, name: name)
	}
}
