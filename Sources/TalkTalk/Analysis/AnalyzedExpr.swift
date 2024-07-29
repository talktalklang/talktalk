//
//  AnalyzedExpr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public indirect enum ValueType {
	public static func == (lhs: ValueType, rhs: ValueType) -> Bool {
		lhs.description == rhs.description
	}

	case int, function(String, ValueType, AnalyzedParamsExpr, [Analyzer.Environment.Capture]), bool, error(String), none, void, placeholder(Int)

	public var description: String {
		switch self {
		case .int:
			return "int"
		case let .function(name, returnType, args, captures):
			let captures = captures.isEmpty ? "" : "[\(captures.map(\.name).joined(separator: ", "))] "
			return "fn \(name)(\(args.params.map(\.name).joined(separator: ", "))) -> \(captures)(\(returnType.description))"
		case .bool:
			return "bool"
		case .error(let msg):
			return "error: \(msg)"
		case .none:
			return "none"
		case .void:
			return "void"
		case .placeholder:
			return "placeholder"
		}
	}
}

public protocol AnalyzedExpr: Expr {
	var type: ValueType { get set }

	func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor
}
