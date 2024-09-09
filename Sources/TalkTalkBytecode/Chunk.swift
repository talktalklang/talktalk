//
//  Chunk.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//
import Foundation

// A Chunk represents a basic unit of code for a function. Function definitions
// each have a chunk.
public final class Chunk: Codable {
	public enum CodingKeys: CodingKey {
		// We're explicitly leaving out `parent` here because it's only needed during compilation and we want to prevent cycles.
		case name, code, lines, constants, data, arity, symbol, path, depth, localsCount, upvalueCount, locals, upvalueNames
	}

	public let name: String
	public let symbol: Symbol
	public let path: String

	// The main code that the VM runs. It's a mix of opcodes and opcode operands
	public var code: ContiguousArray<Code> = []

	// Tracks the code array so we can output line numbers when disassambling
	public var lines: [UInt32] = []

	// Constant values emitted from literals found in the source
	public var constants: [Value] = []

	// Larger blobs of data like strings from literals found in the source
	public var data: [StaticData] = []

	// How many arguments should this chunk expect
	public var arity: Byte = 0
	public var depth: Byte = 0
	public var parent: Chunk?

	// How many locals does this chunk worry about? We start at 1 to reserve 0
	// for things like `self`.
	public var localsCount: Byte = 1

	// How many upvalues does this chunk refer to
	public var upvalueCount: Byte = 0

	// For debugging names used in this chunk
	public var locals: [Symbol] = []
	public var upvalueNames: [String] = []

	public init(name: String, symbol: Symbol, path: String) {
		self.name = name
		self.symbol = symbol
		self.path = path
	}

	public init(name: String, symbol: Symbol, parent: Chunk?, arity: Byte, depth: Byte, path: String) {
		self.name = name
		self.parent = parent
		self.arity = arity
		self.depth = depth
		self.symbol = symbol
		self.path = path
	}

	public func finalize() -> Chunk {
		write(.return, line: 0)
		return self
	}

	public func emit(jump opcode: Opcode, line: UInt32) -> Int {
		// Write the jump instruction first
		write(opcode, line: line)

		// Use two bytes for the offset, which lets us jump over 65k bytes of code.
		// We'll fill these in with patchJump later.
		write(.jumpPlaceholder, line: line)
		write(.jumpPlaceholder, line: line)

		// Return the current location of our chunk code, offset by 2 (since that's
		// where we're gonna store our offset.
		return code.count - 2
	}

	public func patchJump(_ offset: Int) throws {
		// -2 to adjust for the bytecode for the jump offset itself
		let jump = code.count - offset - 2
		if jump > UInt16.max {
			throw BytecodeError.jumpSizeTooLarge
		}

		// Go back and replace the two placeholder bytes from emit(jump:)
		// the actual offset to jump over.
		let (a, b) = uint16ToBytes(jump)
		code[offset] = .byte(a)
		code[offset + 1] = .byte(b)
	}

	public func emit(loop backToInstruction: Int, line: UInt32) {
		write(.loop, line: line)

		let offset = code.count - backToInstruction + 2
		let (a, b) = uint16ToBytes(offset)

		write(byte: a, line: line)
		write(byte: b, line: line)
	}

	public func emit(opcode: Opcode, line: UInt32) {
		write(byte: opcode.byte, line: line)
	}

//	public func emit(byte: Byte, line: UInt32) {
//		write(byte: byte, line: line)
//	}

	public func emit(_ code: Code, line: UInt32) {
		write(code, line: line)
	}

	public func emitClosure(subchunk: Symbol, line: UInt32) {
		// Emit the opcode to define a closure
		write(.defClosure, line: line)
		write(.symbol(subchunk), line: line)
	}

	public func emit(constant value: Value, line: UInt32) {
		write(.constant, line: line)
		write(byte: write(constant: value), line: line)
	}

	// Emit static data for the program
	public func emit(data value: StaticData, line: UInt32) {
		let start = data.count
		data.append(value)
		emit(opcode: .data, line: line)
		emit(.byte(Byte(start)), line: line)
	}

	private func write(constant value: Value) -> Byte {
		let idx = constants.count
		constants.append(value)
		return Byte(idx)
	}

	private func write(_ opcode: Opcode, line: UInt32) {
		write(byte: opcode.byte, line: line)
	}

	private func write(_ code: Code, line: UInt32) {
		self.code.append(code)
		self.lines.append(line)
	}

	private func write(byte: Byte, line: UInt32) {
		code.append(.byte(byte))
		lines.append(line)
	}

	private func uint16ToBytes(_ uint16: Int) -> (Byte, Byte) {
		let a = (uint16 >> 8) & 0xFF
		let b = (uint16 & 0xFF)

		return (Byte(a), Byte(b))
	}
}

extension Chunk: Equatable {
	public static func == (lhs: Chunk, rhs: Chunk) -> Bool {
		let keypaths: [PartialKeyPath<Chunk>] = [
			\.name,
			\.code,
			\.constants,
			\.lines,
			\.arity,
			\.upvalueCount,
		]

		for keypath in keypaths {
			let lhs = lhs[keyPath: keypath]
			let rhs = rhs[keyPath: keypath]

			guard let lhs = lhs as? any Equatable else {
				return false
			}

			if !lhs.equals(rhs) {
				return false
			}
		}

		return true
	}
}

private extension Equatable {
	func equals(_ any: some Any) -> Bool { self == any as? Self }
}
