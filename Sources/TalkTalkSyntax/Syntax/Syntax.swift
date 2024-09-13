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
	var isStandardLibrary: Bool {
		[
			"Array.tlk",
			"Dictionary.tlk",
			"Int.tlk",
			"String.tlk"
		].contains(id.path)
	}

	var semanticLocation: SourceLocation? {
		nil
	}

	func cast<T: Syntax>(_: T.Type, _ file: String = #file, _ line: UInt32 = #line) -> T {
		if let casted = self as? T {
			return casted
		} else {
			// swiftlint:disable fatal_error
			fatalError("Could not cast \(type(of: self)) \(self) to \(T.self) (\(file):\(line))")
			// swiftlint:enable fatal_error
		}
	}

	func `as`<T: Syntax>(_: T.Type) -> T? {
		self as? T
	}

	var description: String {
		do {
			switch self {
			case let syntax as any Expr:
				return try syntax.accept(Formatter(), Formatter.Context())
			case let syntax as any Decl:
				return try syntax.accept(Formatter(), Formatter.Context())
			case let syntax as any Stmt:
				return try syntax.accept(Formatter(), Formatter.Context())
			default:
				return "No description found for \(debugDescription)"
			}
		} catch {
			return "Error getting description: \(error)"
		}
	}

	var debugDescription: String {
		"\(Self.self)(location: \(location), children: \(children.map(\.debugDescription).joined(separator: ", "))"
	}
}
