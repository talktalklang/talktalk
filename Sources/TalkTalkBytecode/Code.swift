//
//  Code.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/8/24.
//

public enum Code: Codable, Equatable, Sendable {
	public enum InvalidCodeError: Error {
		case invalidCode(Code, String)
	}

	case byte(Byte)
	case opcode(Opcode)
	case symbol(StaticSymbol)
	case capture(Capture)

	@inline(__always)
	public func asByte() throws -> Byte {
		if case let .byte(byte) = self {
			return byte
		}

		throw InvalidCodeError.invalidCode(self, "Expected .byte, got \(self)")
	}

	@inline(__always)
	public func asOpcode() throws -> Opcode {
		if case let .opcode(opcode) = self {
			return opcode
		}

		throw InvalidCodeError.invalidCode(self, "Expected .opcode, got \(self)")
	}

	@inline(__always)
	public func asSymbol() throws -> StaticSymbol {
		if case let .symbol(symbol) = self {
			return symbol
		}

		throw InvalidCodeError.invalidCode(self, "Expected .symbol, got \(self)")
	}

	@inline(__always)
	public func asCapture() throws -> Capture {
		if case let .capture(capture) = self {
			return capture
		}

		throw InvalidCodeError.invalidCode(self, "Expected .capture, got \(self)")
	}
}
