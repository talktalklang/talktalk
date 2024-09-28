//
//  Code.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/8/24.
//

public struct Code: Codable, Equatable, Sendable {
	public enum InvalidCodeError: Error {
		case invalidCode(Code, String)
	}

	var byteValue: Byte?
	var opcodeValue: Opcode?
	var symbolValue: StaticSymbol?
	var captureValue: Capture?

	public static func byte(_ byte: Byte) -> Code {
		Code(byteValue: byte)
	}

	public static func opcode(_ opcode: Opcode) -> Code {
		Code(opcodeValue: opcode)
	}

	public static func symbol(_ symbol: StaticSymbol) -> Code {
		Code(symbolValue: symbol)
	}

	public static func capture(_ capture: Capture) -> Code {
		Code(captureValue: capture)
	}


	@inline(__always)
	public func asByte() throws -> Byte {
		byteValue!
	}

	@inline(__always)
	public func asOpcode() throws -> Opcode {
		opcodeValue!
	}

	@inline(__always)
	public func asSymbol() throws -> StaticSymbol {
		symbolValue!
	}

	@inline(__always)
	public func asCapture() throws -> Capture {
		captureValue!
	}
}
