//
//  Error.swift
//
//
//  Created by Pat Nakajima on 7/7/24.
//
public enum Error: Swift.Error {
	case compiler([Compiler.Error]),
	     parser([Parser.Error])

	func description(in compiler: Compiler) -> String {
		switch self {
		case let .compiler(errors):
			errors.map { $0.description(in: compiler) }.joined(separator: "\n")
		case let .parser(errors):
			errors.map { $0.description(in: compiler) }.joined(separator: "\n")
		}
	}
}
