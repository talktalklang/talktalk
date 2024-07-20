//
//  SourceFile.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

public struct SourceFile {
	public let path: String
	public let source: String

	public init(path: String, source: String) {
		self.path = path
		self.source = source
	}
}
