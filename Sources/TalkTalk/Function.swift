//
//  Function.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
public struct Function: Equatable, Hashable {
	public enum Kind {
		case function, main, method
	}

	private final class Storage {
		var arity: Int
		var chunk: Chunk
		var name: String
		var kind: Kind
		var upvalueCount = 0

		init(arity: Int, chunk: Chunk, name: String, kind: Kind, upvalueCount: Int = 0) {
			self.arity = arity
			self.chunk = chunk
			self.name = name
			self.kind = kind
			self.upvalueCount = upvalueCount
		}
	}

	public static func == (lhs: Function, rhs: Function) -> Bool {
		lhs.arity == rhs.arity && lhs.chunk == rhs.chunk && lhs.name == rhs.name && lhs.kind == rhs.kind && lhs.upvalueCount == rhs.upvalueCount
	}

	private let storage: Storage

	var arity: Int {
		get {
			storage.arity
		}

		set {
			storage.arity = newValue
		}
	}

	var chunk: Chunk {
		get {
			storage.chunk
		}

		set {
			storage.chunk = newValue
		}
	}

	var name: String {
		get {
			storage.name
		}

		set {
			storage.name = newValue
		}
	}

	var kind: Kind {
		storage.kind
	}

	var upvalueCount: Int {
		get {
			storage.upvalueCount
		}

		set {
			storage.upvalueCount = newValue
		}
	}

	init(arity: Int, chunk: Chunk, name: String, kind: Kind = .function, upvalueCount: Int = 0) {
		self.storage = Storage(arity: arity, chunk: chunk, name: name, kind: kind, upvalueCount: upvalueCount)
	}

	public func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(arity)
		hasher.combine(chunk)
		hasher.combine(name)
	}
}
