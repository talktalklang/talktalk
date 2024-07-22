import TalkTalkSyntax

public protocol AbstractBindingTreeVisitor {
	func visit(_ node: BinaryOpExpression)
	func visit(_ node: Block)
	func visit(_ node: Function)
	func visit(_ node: IfExpression)
	func visit(_ node: Literal)
	func visit(_ node: OperatorNode)
	func visit(_ node: Program)
	func visit(_ node: TypeDeclaration)
	func visit(_ node: VarLetDeclaration)
	func visit(_ node: VoidNode)
}
