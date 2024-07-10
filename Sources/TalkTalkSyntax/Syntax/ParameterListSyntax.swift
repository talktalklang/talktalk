//
//  ParameterListSyntax.swift
//
//
//  Created by Pat Nakajima on 7/9/24.
//
public struct ParameterListSyntax: Syntax {
	public let position: Int
	public let length: Int
	public let parameters: [IdentifierSyntax]

	public subscript(_ index: Int) -> IdentifierSyntax {
		return parameters[index]
	}

	public var count: Int {
		parameters.count
	}

	public var isEmpty: Bool {
		parameters.isEmpty
	}

	public var description: String {
		""
	}

	public var debugDescription: String {
		"""
		ParameterListSyntax(position: \(position), length: \(length))
			parameters:
				\(parameters.map(\.debugDescription).joined(separator: "\n\t\t"))
		"""
	}
}
