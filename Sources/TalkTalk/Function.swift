//
//  Function.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
public struct Function: Equatable, Hashable {
	public enum Kind {
		case function, main
	}

	public static func == (lhs: Function, rhs: Function) -> Bool {
		lhs.arity == rhs.arity && lhs.chunk == rhs.chunk && lhs.name == rhs.name && lhs.kind == rhs.kind && lhs.upvalueCount == rhs.upvalueCount
	}

	var arity: Int
	var chunk: Chunk
	var name: String
	var kind: Kind
	var upvalueCount = 0

	init(arity: Int, chunk: Chunk, name: String, kind: Kind = .function) {
		self.arity = arity
		self.chunk = chunk
		self.name = name
		self.kind = kind
	}

	public func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(arity)
		hasher.combine(chunk)
		hasher.combine(name)
	}
}
