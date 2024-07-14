// Allows traversal of the AST
public protocol ASTVisitor {
	// What value the visitors should return
	associatedtype Value

	// Passed to each visit call
	associatedtype Context

	mutating func visit(_ node: ProgramSyntax, context: Context) -> Value

	// Decls
	mutating func visit(_ node: FunctionDeclSyntax, context: Context) -> Value
	mutating func visit(_ node: VarDeclSyntax, context: Context) -> Value
	mutating func visit(_ node: ClassDeclSyntax, context: Context) -> Value
	mutating func visit(_ node: InitDeclSyntax, context: Context) -> Value
	mutating func visit(_ node: PropertyDeclSyntax, context: Context) -> Value

	// Stmts
	mutating func visit(_ node: ExprStmtSyntax, context: Context) -> Value
	mutating func visit(_ node: BlockStmtSyntax, context: Context) -> Value
	mutating func visit(_ node: IfStmtSyntax, context: Context) -> Value
	mutating func visit(_ node: StmtSyntax, context: Context) -> Value
	mutating func visit(_ node: WhileStmtSyntax, context: Context) -> Value
	mutating func visit(_ node: ReturnStmtSyntax, context: Context) -> Value

	// Exprs
	mutating func visit(_ node: GroupExpr, context: Context) -> Value
	mutating func visit(_ node: CallExprSyntax, context: Context) -> Value
	mutating func visit(_ node: UnaryExprSyntax, context: Context) -> Value
	mutating func visit(_ node: BinaryExprSyntax, context: Context) -> Value
	mutating func visit(_ node: IdentifierSyntax, context: Context) -> Value
	mutating func visit(_ node: IntLiteralSyntax, context: Context) -> Value
	mutating func visit(_ node: StringLiteralSyntax, context: Context) -> Value
	mutating func visit(_ node: VariableExprSyntax, context: Context) -> Value
	mutating func visit(_ node: AssignmentExpr, context: Context) -> Value
	mutating func visit(_ node: LiteralExprSyntax, context: Context) -> Value
	mutating func visit(_ node: PropertyAccessExpr, context: Context) -> Value
	mutating func visit(_ node: ArrayLiteralSyntax, context: Context) -> Value
	mutating func visit(_ node: IfExprSyntax, context: Context) -> Value

	// Utility
	mutating func visit(_ node: UnaryOperator, context: Context) -> Value
	mutating func visit(_ node: BinaryOperatorSyntax, context: Context) -> Value
	mutating func visit(_ node: ArgumentListSyntax, context: Context) -> Value
	mutating func visit(_ node: ParameterListSyntax, context: Context) -> Value
	mutating func visit(_ node: ErrorSyntax, context: Context) -> Value
	mutating func visit(_ node: TypeDeclSyntax, context: Context) -> Value
}
