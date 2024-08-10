import TalkTalkSyntax

public protocol ABTVisitor {
	associatedtype Value

	func visit(_ node: BinaryOpExpression) -> Value
	func visit(_ node: Block) -> Value
	func visit(_ node: Function) -> Value
	func visit(_ node: ParameterList) -> Value
	func visit(_ node: IfExpression) -> Value
	func visit(_ node: Literal) -> Value
	func visit(_ node: OperatorNode) -> Value
	func visit(_ node: Program) -> Value
	func visit(_ node: TypeDeclaration) -> Value
	func visit(_ node: VarLetDeclaration) -> Value
	func visit(_ node: CallExpression) -> Value
	func visit(_ node: ArgumentList) -> Value
	func visit(_ node: VoidNode) -> Value
	func visit(_ node: TODONode) -> Value
	func visit(_ node: UnknownSemanticNode) -> Value
	func visit(_ node: AssignmentExpression) -> Value
	func visit(_ node: VarExpression) -> Value
}
