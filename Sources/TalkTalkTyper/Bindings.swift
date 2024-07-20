//
//  Results.swift
//
//
//  Created by Pat Nakajima on 7/15/24.
//
import TalkTalkSyntax

public class Bindings {
	public var ast: any Syntax
	public var errors: [TypeError] = []
	public var warnings: [String] = []
	public var file: SourceFile?
	var typedefs: [Int: TypedValue] = [:]

	init(ast: any Syntax) {
		self.ast = ast
	}

	public func debug(at node: any Syntax) {
		let source = file!.source

		var i = 1
		for line in source.components(separatedBy: .newlines) {
			print(line)
			if i == node.line {
				print(String(repeating: " ", count: source.inlineOffset(for: node.position, line: i)), terminator: "")
				print("^ HERE")
			}

			i += 1
		}
	}

	public func type(for node: any Syntax) -> TypedValue? {
		for i in node.range {
			return typedef(at: i)
		}

		return nil
	}

	public func capture(_ node: any Syntax, _ typedValue: TypedValue) {
		if typedValue.definition.position != node.position, let existing = type(for: typedValue.definition) {
			capture(typedValue.definition, existing)
		}

		var typedValue = typedValue
		typedValue.isEscaping = true
		typedefs[node.hashValue] = typedValue
	}

	public func define(_ node: any Syntax, as typedValue: TypedValue) {
		typedefs[node.hashValue] = typedValue
	}

	public func typedef(at position: Int) -> TypedValue? {
		for node in ast.nodes(at: position) {
			if let typedef = typedefs[node.hashValue] {
				return typedef
			}
		}

		return nil
	}
}
