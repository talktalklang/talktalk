// Allows traversal of the AST
public protocol ASTVisitor {
	// What value the visitors should return
	associatedtype Value

	// Passed to each visit call
	associatedtype Context

	mutating func visit(_ node: ProgramSyntax, context: inout Context) -> Value

	// Decls
	mutating func visit(_ node: FunctionDeclSyntax, context: inout Context) -> Value
	mutating func visit(_ node: VarDeclSyntax, context: inout Context) -> Value
	mutating func visit(_ node: ClassDeclSyntax, context: inout Context) -> Value
	mutating func visit(_ node: InitDeclSyntax, context: inout Context) -> Value

	// Stmts
	mutating func visit(_ node: ExprStmtSyntax, context: inout Context) -> Value
	mutating func visit(_ node: BlockStmtSyntax, context: inout Context) -> Value
	mutating func visit(_ node: IfStmtSyntax, context: inout Context) -> Value
	mutating func visit(_ node: StmtSyntax, context: inout Context) -> Value
	mutating func visit(_ node: WhileStmtSyntax, context: inout Context) -> Value
	mutating func visit(_ node: ReturnStmtSyntax, context: inout Context) -> Value

	// Exprs
	mutating func visit(_ node: GroupExpr, context: inout Context) -> Value
	mutating func visit(_ node: CallExprSyntax, context: inout Context) -> Value
	mutating func visit(_ node: UnaryExprSyntax, context: inout Context) -> Value
	mutating func visit(_ node: BinaryExprSyntax, context: inout Context) -> Value
	mutating func visit(_ node: IdentifierSyntax, context: inout Context) -> Value
	mutating func visit(_ node: IntLiteralSyntax, context: inout Context) -> Value
	mutating func visit(_ node: StringLiteralSyntax, context: inout Context) -> Value
	mutating func visit(_ node: VariableExprSyntax, context: inout Context) -> Value
	mutating func visit(_ node: AssignmentExpr, context: inout Context) -> Value
	mutating func visit(_ node: LiteralExprSyntax, context: inout Context) -> Value
	mutating func visit(_ node: PropertyAccessExpr, context: inout Context) -> Value
	mutating func visit(_ node: ArrayLiteralSyntax, context: inout Context) -> Value

	// Utility
	mutating func visit(_ node: UnaryOperator, context: inout Context) -> Value
	mutating func visit(_ node: BinaryOperatorSyntax, context: inout Context) -> Value
	mutating func visit(_ node: ArgumentListSyntax, context: inout Context) -> Value
	mutating func visit(_ node: ParameterListSyntax, context: inout Context) -> Value
	mutating func visit(_ node: ErrorSyntax, context: inout Context) -> Value
	mutating func visit(_ node: TypeDeclSyntax, context: inout Context) -> Value
}
