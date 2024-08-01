//
//  Syntax.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public protocol Syntax: CustomStringConvertible {
	var location: SourceLocation { get }
	func accept<V: Visitor>(_ visitor: V, _ scope: V.Context) throws -> V.Value
}

public extension Syntax {
	func cast<T: Syntax>(_: T.Type) -> T {
		self as! T
	}

	var description: String {
		switch self {
		case let syntax as any Expr:
			try! syntax.accept(Formatter(), Formatter.Context())
		case let syntax as any Decl:
			try! syntax.accept(Formatter(), Formatter.Context())
		default:
			"No description found for \(self)"
		}
	}
}
