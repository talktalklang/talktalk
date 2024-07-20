//
//  Syntax.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
public protocol Syntax: CustomStringConvertible, Hashable {
	var start: Token { get }
	var end: Token { get }

	func accept<Visitor: ASTVisitor>(_ visitor: Visitor, context: Visitor.Context) -> Visitor.Value
}

public extension Syntax {
	func at<T: Syntax>(_ keyPath: KeyPath<Self, T>) -> T {
		self[keyPath: keyPath]
	}

	func `as`<T: Syntax>(_: T.Type) -> T? {
		if let cast = self as? T {
			return cast
		}

		return nil
	}

	func cast<T: Syntax>(_: T.Type) -> T {
		self as! T
	}

	var description: String {
		ASTFormatter.format(self)
	}

	var position: Int {
		start.start
	}

	var length: Int {
		(end.start + end.length) - start.start
	}

	var line: Int {
		start.line
	}

	var range: Range<Int> {
		start.start ..< (end.start + end.length)
	}

	func nodes(at position: Int) -> [any Syntax] {
		var result: [any Syntax] = []
		var visitor = GenericVisitor { node, _ in
			if node.range.contains(position) {
				result.append(node)
			}
		}

		visitor.visit(self, context: ())

		return result.sorted(by: { $0.length < $1.length })
	}

	func node(at position: Int) -> any Syntax {
		var result: any Syntax = self
		var visitor = GenericVisitor { node, _ in
			if node.range.contains(position), node.range.count < result.range.count {
				result = node
			}
		}

		visitor.visit(self, context: ())
		return result
	}
}
