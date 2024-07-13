//
//  ValueType.swift
//
//
//  Created by Pat Nakajima on 7/12/24.
//
import TalkTalkSyntax

public struct Property {
	let name: String
	let type: ValueType
	let definition: any Syntax
}

// I wanted to call this `Type` but swift was not wild about that.
public struct ValueType: Equatable, CustomStringConvertible {
	public static func == (lhs: ValueType, rhs: ValueType) -> Bool {
		return lhs.id == rhs.id
	}

	public class Return: Equatable {
		public static func == (lhs: Return, rhs: Return) -> Bool {
			lhs.value == rhs.value
		}

		let value: ValueType

		init(value: ValueType) {
			self.value = value
		}
	}

	public class Associated: Equatable {
		public static func == (lhs: Associated, rhs: Associated) -> Bool {
			lhs.value == rhs.value
		}

		let value: ValueType

		init(value: ValueType) {
			self.value = value
		}
	}

	public class OfType: Equatable {
		public static func == (lhs: OfType, rhs: OfType) -> Bool {
			lhs.value == rhs.value
		}

		let value: ValueType

		init(value: ValueType) {
			self.value = value
		}
	}

	public let id: Int
	public let name: String
	public var ofType: OfType?
	public let properties: [String: Property]?
	public var returns: Return?
	public let associated: [Associated]
	public let definition: any Syntax

	init(
		id: Int,
		name: String,
		definition: any Syntax,
		ofType: ((Self) -> ValueType)? = nil,
		properties: [String: Property]? = nil,
		returns: ((Self) -> ValueType)? = nil,
		associated: [ValueType] = []
	) {
		self.id = id
		self.name = name
		self.definition = definition
		self.properties = properties
		self.associated = associated.map(Associated.init)

		self.ofType = ofType.flatMap { .init(value: $0(self)) }
		self.returns = returns.flatMap { .init(value: $0(self)) }
	}

	init(
		id: Int,
		name: String,
		definition: any Syntax,
		associated: [ValueType] = []
	) {
		self.id = id
		self.name = name
		self.definition = definition
		self.properties = nil
		self.ofType = nil
		self.associated = associated.map(Associated.init)
		self.returns = nil
	}

	public var description: String {
		var result = name

		if !associated.isEmpty {
			result += "<"
			result += associated.map(\.value.description).joined(separator: ", ")
			result += ">"
		}

		if let returns {
			result += " -> (\(returns.value.description))"
		}

		return result
	}

	func assignable(from other: ValueType) -> Bool {
		self == other
	}

	func property(named name: String) -> Property? {
		if let ofType {
			return ofType.value.properties?[name]
		}

		return nil
	}

	var isCallable: Bool {
		returns != nil
	}
}

public extension ValueType {
	static let builtins: [ValueType] = [
		.void,
		.int,
		.string,
		.bool,
	]

	static let void = ValueType(
		id: 0,
		name: "Void",
		definition: ProgramSyntax.main
	)

	static let int = ValueType(
		id: -1,
		name: "Int",
		definition: ProgramSyntax.main
	)

	static let string = ValueType(
		id: -2,
		name: "String",
		definition: ProgramSyntax.main
	)

	static let bool = ValueType(
		id: -3,
		name: "Bool",
		definition: ProgramSyntax.main
	)

	static func array(_ element: ValueType) -> ValueType {
		ValueType(
			id: -4,
			name: "Array",
			definition: ProgramSyntax.main,
			associated: [element]
		)
	}

	static func function(_ returns: ValueType) -> ValueType {
		ValueType(
			id: -5,
			name: "Function",
			definition: ProgramSyntax.main,
			returns: { _ in returns }
		)
	}

	static let `nil` = ValueType(
		id: -6,
		name: "Nil",
		definition: ProgramSyntax.main
	)
}
