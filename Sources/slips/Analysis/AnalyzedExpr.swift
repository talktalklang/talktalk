//
//  Expr.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public indirect enum ValueType {
	public static func == (lhs: ValueType, rhs: ValueType) -> Bool {
		lhs.description == rhs.description
	}

	case int, function(ValueType, [String]), bool, error, none, void

	public var description: String {
		switch self {
		case .int:
			"int"
		case .function(let returnType, let args):
			"fn(\(args.joined(separator: ", "))) -> (\(returnType.description))"
		case .bool:
			"bool"
		case .error:
			"error"
		case .none:
			"none"
		case .void:
			"void"
		}
	}
}

public protocol AnalyzedExpr: Expr {
	var type: ValueType { get }
}

