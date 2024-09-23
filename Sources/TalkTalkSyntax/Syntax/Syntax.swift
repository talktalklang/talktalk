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
			"Array.talk",
			"Dictionary.talk",
			"Int.talk",
			"String.talk",
		].contains(id.path)
	}

	var semanticLocation: SourceLocation? {
		nil
	}

	func cast<T: Syntax>(_: T.Type, _ file: String = #file, _ line: UInt32 = #line) -> T {
		if let casted = self as? T {
			casted
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
			let visitor = FormatterVisitor(commentsStore: CommentStore(comments: []))
			let context = FormatterVisitor.Context(kind: .topLevel)
			let doc = try accept(visitor, context)
			return Formatter.format(document: doc, width: 80)
		} catch {
			return "Error getting description: \(error)"
		}
	}

	var debugDescription: String {
		"\(Self.self)(location: \(location), children: \(children.map(\.debugDescription).joined(separator: ", "))"
	}
}
