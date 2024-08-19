//
//  Pointer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/18/24.
//

public enum Pointer: Equatable, Sendable, Codable, Hashable {
	case stack(Byte),
			 heap(Byte),
			 upvalue(Byte),
			 moduleValue(Byte),
			 moduleFunction(Byte),
			 moduleStruct(Byte),
			 builtinFunction(Byte),
			 null

	public init(bytes: (Byte, Byte)) {
		switch bytes {
		case (0, let byte):
			self = .stack(byte)
		case (1, let byte):
			self = .heap(byte)
		case (2, let byte):
			self = .moduleValue(byte)
		case (3, let byte):
			self = .moduleFunction(byte)
		case (4, let byte):
			self = .builtinFunction(byte)
		case (5, let byte):
			self = .moduleStruct(byte)
		case (6, let byte):
			self = .upvalue(byte)
		case (7, _):
			self = .null
		default:
			fatalError("invalid pointer bytes: \(bytes)")
		}
	}

	public var bytes: (Byte, Byte) {
		switch self {
		case .stack(let byte):
			(0, byte)
		case .heap(let byte):
			(1, byte)
		case .moduleValue(let byte):
			(2, byte)
		case .moduleFunction(let byte):
			(3, byte)
		case .builtinFunction(let byte):
			(4, byte)
		case .moduleStruct(let byte):
			(5, byte)
		case .upvalue(let byte):
			(6, byte)
		case .null:
			(7, 0)
		}
	}
}
