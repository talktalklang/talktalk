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

	case byte(Byte), opcode(Opcode), symbol(Symbol)

	public func asByte() throws -> Byte {
		guard case let .byte(byte) = self else {
			throw InvalidCodeError.invalidCode(self, "expected byte")
		}

		return byte
	}

	public func asOpcode() throws -> Opcode {
		guard case let .opcode(opcode) = self else {
			throw InvalidCodeError.invalidCode(self, "expected opcode")
		}

		return opcode
	}

	public func asSymbol() throws -> Symbol {
		guard case let .symbol(symbol) = self else {
			throw InvalidCodeError.invalidCode(self, "expected symbol")
		}

		return symbol
	}
}
