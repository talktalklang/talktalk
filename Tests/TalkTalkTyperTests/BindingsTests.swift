import TalkTalkSyntax
@testable import TalkTalkTyper
import Testing

struct BindingsTests {
	@Test("binds") func binds() throws {
		var visitor = GenericVisitor { node, _ in
			print(node.hashValue, terminator: " ")
			print(node.description)
		}

		let source = """
		let foo = "bar"
		"""

		let ast = try SyntaxTree.parse(source: source)
		visitor.visit(ast, context: ())
	}
}
