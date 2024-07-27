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

	case int, function(ValueType, [any Param]), bool, error, none, void, placeholder(Int)

	public var description: String {
		switch self {
		case .int:
			"int"
		case let .function(returnType, args):
			"fn(\(args.map(\.name).joined(separator: ", "))) -> (\(returnType.description))"
		case .bool:
			"bool"
		case .error:
			"error"
		case .none:
			"none"
		case .void:
			"void"
		case .placeholder(_):
			"placeholder"
		}
	}
}

public protocol AnalyzedExpr: Expr {
	var type: ValueType { get set }

	func accept<V>(_ visitor: V, _ scope: V.Context) -> V.Value where V: AnalyzedVisitor
}
