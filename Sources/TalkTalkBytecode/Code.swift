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

	case byte(Byte), opcode(Opcode), symbol(StaticSymbol), capture(Capture)

	@inline(__always)
	public func asByte() throws -> Byte {
		guard case let .byte(byte) = self else {
			throw InvalidCodeError.invalidCode(self, "expected byte")
		}

		return byte
	}

	@inline(__always)
	public func asOpcode() throws -> Opcode {
		guard case let .opcode(opcode) = self else {
			throw InvalidCodeError.invalidCode(self, "expected opcode")
		}

		return opcode
	}

	@inline(__always)
	public func asSymbol() throws -> StaticSymbol {
		guard case let .symbol(symbol) = self else {
			throw InvalidCodeError.invalidCode(self, "expected symbol, got \(self)")
		}

		return symbol
	}

	@inline(__always)
	public func asCapture() throws -> Capture {
		guard case let .capture(capture) = self else {
			throw InvalidCodeError.invalidCode(self, "expected capture")
		}

		return capture
	}
}
