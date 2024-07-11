//
//  DeclContext.swift
//
//
//  Created by Pat Nakajima on 7/11/24.
//
public enum DeclContext {
	case topLevel, `class`, function, `init`

	var allowedDecls: Set<Token.Kind> {
		switch self {
		case .`init`:
			[.func, .class, .var]
		case .topLevel:
			[.func, .class, .var]
		case .class:
			[.func, .class, .`init`, .var]
		case .function:
			[.func, .class, .var]
		}
	}
}
