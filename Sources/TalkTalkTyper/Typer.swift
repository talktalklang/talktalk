import TalkTalkSyntax

public struct Error: Swift.Error, @unchecked Sendable {
	public let syntax: any Syntax
	public let message: String
}

public struct Typer {
	let ast: ProgramSyntax

	public var errors: [Error] = []

	public init(source: String) {
		self.ast = SyntaxTree.parse(source: source)
	}

	public func check() -> Results {
		var visitor = TyperVisitor(ast: ast)
		return visitor.check()
	}
}
