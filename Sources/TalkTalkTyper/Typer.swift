import TalkTalkSyntax

public struct TypeError: Swift.Error, @unchecked Sendable {
	public let syntax: any Syntax
	public let message: String
	public let definition: TypedValue?

	public func report(in file: SourceFile) {
		let source = file.source

		let lineIndex = syntax.line - 1

		let lineText = source.components(separatedBy: .newlines)[lineIndex]
		let lineOffset = source.inlineOffset(for: syntax.position, line: lineIndex + 1)

		print("Problem found in \(file.path) on line \(syntax.line) at \(syntax.position):")

		// previous line for context
		if lineIndex > 0 {
			let lineText = source.components(separatedBy: .newlines)[lineIndex - 1]
			print("\(syntax.line - 1)\t|\t\t\(lineText)")
		}

		print("\(syntax.line)\t|\t\t" + lineText)
		print(" \t|\t\t" + String(repeating: " ", count: lineOffset - 1) + "^ \(message)")

		if let definition, let ref = definition.ref {
			print(" \t|")
			print(" \t| Type set as \(definition.type.description) on \(ref.definition.line):")
			print(" \t|")
			print("\(ref.definition.line)\t|\t\t" + source.components(separatedBy: .newlines)[ref.definition.line - 1])
			let offset = source.inlineOffset(for: ref.definition.position, line: ref.definition.line)
			print(" \t|\t\t" + String(repeating: " ", count: offset - 1) + "^")
		}
	}
}

public struct Typer {
	public let ast: any Syntax
	let context: Context
	public let file: SourceFile

	public var errors: [TypeError] = []

	public init(ast: any Syntax) {
		self.ast = ast
		self.context = Context()
		self.file = .init(path: "", source: "")
	}

	public init(source: SourceFile) throws {
		self.ast = try SyntaxTree.parse(source: source)
		self.context = Context()
		self.file = source

		for builtin in ValueType.builtins {
			context.define(type: builtin)
		}
	}

	public func check() -> Bindings {
		let visitor = TyperVisitor(ast: ast)
		return visitor.visit(ast: ast, context: context)
	}
}
