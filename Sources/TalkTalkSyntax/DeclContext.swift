//
//  DeclContext.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
public enum DeclContext: CustomStringConvertible {
	case topLevel, `class`, function, `init`, ifExpr

	public var description: String {
		switch self {
		case .topLevel:
			"top level"
		case .class:
			"class body"
		case .function:
			"function body"
		case .`init`:
			"init body"
		case .ifExpr:
			"if expression"
		}
	}

	var allowedDecls: Set<Token.Kind> {
		switch self {
		case .`init`:
			[.func, .class, .var, .let, .return]
		case .topLevel:
			[.func, .class, .var, .let]
		case .class:
			[.func, .class, .`init`, .var, .let]
		case .function:
			[.func, .class, .var, .let, .return]
		case .ifExpr:
			[]
		}
	}
}
