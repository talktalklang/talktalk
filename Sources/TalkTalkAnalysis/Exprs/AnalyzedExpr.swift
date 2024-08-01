//
//  AnalyzedExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkSyntax

public struct Property {
	public let name: String
	public let type: ValueType
	public let expr: any Syntax
	public let isMutable: Bool
}

public class StructType {
	public let name: String?
	public private(set) var properties: [String: Property]
	public private(set) var methods: [String: Property]
	public private(set) var propertyOffsets: [String: Int]
	public private(set) var methodOffsets: [String: Int]

	public init(name: String? = nil, properties: [String: Property], methods: [String: Property]) {
		self.name = name
		self.properties = properties
		self.methods = methods
		self.propertyOffsets = [:]
		self.methodOffsets = [:]
	}

	public func offset(for propertyName: String) -> Int {
		propertyOffsets[propertyName]!
	}

	public func offset(method propertyName: String) -> Int {
		methodOffsets[propertyName]!
	}

	public func add(property: Property) {
		propertyOffsets[property.name] = properties.count
		properties[property.name] = property
	}

	public func add(method property: Property) {
		if methodOffsets[property.name] == nil {
			methodOffsets[property.name] = methods.count
		}

		methods[property.name] = property
	}
}

public indirect enum ValueType {
	public static func == (lhs: ValueType, rhs: ValueType) -> Bool {
		lhs.description == rhs.description
	}

	case int,
			 // function name, return type, param types, captures
			 function(String, ValueType, AnalyzedParamsExpr, [Analyzer.Environment.Capture]),
			 bool,
			 `struct`(StructType),
			 instance(ValueType),
			 instanceValue(ValueType),
			 error(String),
			 none,
			 void,
			 placeholder(Int)

	public var description: String {
		switch self {
		case .int:
			return "int"
		case let .function(name, returnType, args, captures):
			let captures = captures.isEmpty ? "" : "[\(captures.map(\.name).joined(separator: ", "))] "
			return "fn \(name)(\(args.params.description)) -> \(captures)(\(returnType.description))"
		case .bool:
			return "bool"
		case .error(let msg):
			return "error: \(msg)"
		case .none:
			return "none"
		case .void:
			return "void"
		case let .struct(structType):
			return "struct \(structType.name ?? "<unnamed>")"
		case .placeholder:
			return "placeholder"
		case let .instance(valueType):
			return "instance \(valueType.description)"
		case let .instanceValue(structType):
			return "struct instance value \(structType)"
		}
	}
}

public protocol AnalyzedExpr: Expr {
	var type: ValueType { get set }

	func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor
}
