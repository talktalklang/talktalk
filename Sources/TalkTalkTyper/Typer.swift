import TalkTalkSyntax

extension String {
	func inlineOffset(for position: Int, line: Int) -> Int {
		var offset = 0
		for (i, lineText) in components(separatedBy: .newlines).enumerated() {
			if i == line {
				return position - offset
			}

			offset += lineText.count
		}

		return 0
	}
}

public struct TypeError: Swift.Error, @unchecked Sendable {
	public let syntax: any Syntax
	public let message: String
	public let def: TypeDef?

	public func report(in source: String) {
		let lineIndex = syntax.line - 1

		let lineText = source.components(separatedBy: .newlines)[lineIndex]
		let lineOffset = source.inlineOffset(for: syntax.start.start, line: lineIndex)

		print("Problem found on line \(syntax.line):")
		print("\t" + lineText)
		print("\t" + String(repeating: " ", count: lineOffset - 1) + "^")
		print(message)
		print()

		if let def {
			print("Type set as \(def.definition.description) on \(def.definition.line):")
			print("\t" + source.components(separatedBy: .newlines)[def.definition.line - 1])
			let offset = source.inlineOffset(for: def.definition.start.start, line: def.definition.line - 1)
			print("\t" + String(repeating: " ", count: offset) + "^")
		}
	}
}

public struct Typer {
	let ast: ProgramSyntax

	public var errors: [TypeError] = []

	public init(source: String) {
		self.ast = SyntaxTree.parse(source: source)
	}

	public func check() -> Results {
		var visitor = TyperVisitor(ast: ast)
		return visitor.check()
	}
}
