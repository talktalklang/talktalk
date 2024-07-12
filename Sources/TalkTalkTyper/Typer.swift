import TalkTalkSyntax

public struct TypeError: Swift.Error, @unchecked Sendable {
	public let syntax: any Syntax
	public let message: String

	public func report(in source: String) {
		var offset = 0
		let lineIndex = syntax.line - 1
		
		for line in source.components(separatedBy: .newlines) {
			let 

			if syntax.range.contains(lineIndex) {

			}

			offset += line.count
		}


		print()
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
