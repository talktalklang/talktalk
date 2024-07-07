//
//  Error.swift
//
//
//  Created by Pat Nakajima on 7/7/24.
//
public enum Error: Swift.Error {
	case compiler([Compiler.Error]),
	     parser([Parser.Error])

	var description: String {
		switch self {
		case let .compiler(errors):
			errors.map(\.description).joined(separator: ", ")
		case let .parser(errors):
			errors.map(\.description).joined(separator: ", ")
		}
	}
}
