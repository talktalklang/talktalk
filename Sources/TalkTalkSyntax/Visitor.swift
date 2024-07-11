public protocol ASTVisitor {
	associatedtype Value

	mutating func visit(_ node: ProgramSyntax) -> Value

	// Decls
	mutating func visit(_ node: FunctionDeclSyntax) -> Value
	mutating func visit(_ node: VarDeclSyntax) -> Value

	// Stmts
	mutating func visit(_ node: ExprStmtSyntax) -> Value
	mutating func visit(_ node: BlockStmtSyntax) -> Value
	mutating func visit(_ node: StmtSyntax) -> Value

	// Exprs
	mutating func visit(_ node: GroupExpr) -> Value
	mutating func visit(_ node: CallExprSyntax) -> Value
	mutating func visit(_ node: UnaryExprSyntax) -> Value
	mutating func visit(_ node: BinaryExprSyntax) -> Value
	mutating func visit(_ node: IdentifierSyntax) -> Value
	mutating func visit(_ node: IntLiteralSyntax) -> Value
	mutating func visit(_ node: StringLiteralSyntax) -> Value
	mutating func visit(_ node: VariableExprSyntax) -> Value

	// Utility
	mutating func visit(_ node: UnaryOperator) -> Value
	mutating func visit(_ node: BinaryOperatorSyntax) -> Value
	mutating func visit(_ node: ArgumentListSyntax) -> Value
	mutating func visit(_ node: ParameterListSyntax) -> Value
	mutating func visit(_ node: ErrorSyntax) -> Value
}

