//
//  Syntax.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

import TalkTalkCore

public typealias SyntaxID = TalkTalkCore.SyntaxID

public protocol Syntax: CustomStringConvertible {
	// A unique identifier for every piece of syntax
	var id: SyntaxID { get }

	// Where does this syntax live
	var location: SourceLocation { get }

	// Useful for just traversing the whole tree
	var children: [any Syntax] { get }

	// Let this node be visited by visitors
	func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value

	// If this node starts with a keyword, we can skip that when we're talking about
	// the interesting part of where this syntax starts
	var semanticLocation: SourceLocation? { get }
}

public extension Syntax {
	var semanticLocation: SourceLocation? {
		nil
	}

	func cast<T: Syntax>(_: T.Type, _ file: String = #file, _ line: UInt32 = #line) -> T {
		if self is T {
			self as! T
		} else {
			fatalError("Could not cast \(self) to \(T.self) (\(file):\(line))")
		}
	}

	func `as`<T: Syntax>(_: T.Type) -> T? {
		self as? T
	}

	var description: String {
		switch self {
		case let syntax as any Expr:
			try! syntax.accept(Formatter(), Formatter.Context())
		case let syntax as any Decl:
			try! syntax.accept(Formatter(), Formatter.Context())
		case let syntax as any Stmt:
			try! syntax.accept(Formatter(), Formatter.Context())
		default:
			"No description found for \(debugDescription)"
		}
	}

	var debugDescription: String {
		"\(Self.self)(location: \(location), children: \(children.map(\.debugDescription).joined(separator: ", "))"
	}
}
