//
//  Function.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
public class Function: Equatable, Hashable {
	public enum Kind {
		case function, main
	}

	public static func == (_: Function, _: Function) -> Bool {
		false
	}

	var arity: Int
	let chunk: Chunk
	var name: String
	var kind: Kind

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
