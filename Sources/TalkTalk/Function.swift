//
//  Function.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
public class Function: Equatable, Hashable {
	public enum Kind {
		case function, script
	}

	public static func == (_: Function, _: Function) -> Bool {
		false
	}

	var arity: Int
	let chunk: Chunk
	var name: String

	init(arity: Int, chunk: Chunk, name: String) {
		self.arity = arity
		self.chunk = chunk
		self.name = name
	}

	public func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(arity)
		hasher.combine(chunk)
		hasher.combine(name)
	}
}
