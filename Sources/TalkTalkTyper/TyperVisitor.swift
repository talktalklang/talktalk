import TalkTalkSyntax

public class Results {
	var errors: [Error] = []
	var warnings: [String] = []
	var typedefs: [Range<Int>: TypeDef] = [:]

	public func typedef(at position: Int) -> TypeDef? {
		// TODO: optimize
		for (range, typedef) in typedefs {
			if range.contains(position) {
				return typedef
			}
		}

		return nil
	}
}

struct TyperVisitor: ASTVisitor {
	let ast: ProgramSyntax
	var results: Results = .init()

	mutating func define(_ node: any Syntax, as typedef: TypeDef) {
		results.typedefs[node.position..<node.position + node.length] = typedef
	}

	mutating func error(_ node: any Syntax, _ msg: String) {
		results.errors.append(.init(syntax: node, message: msg))
	}

	func infer(type expr: Expr) -> TypeDef? {
		results.typedef(at: expr.position)
	}

	mutating func check() -> Results {
		results = .init()
		_ = visit(ast)
		return results
	}

	mutating func visit(_ node: ProgramSyntax) -> TypeDef? {
		for decl in node.decls {
			decl.accept(&self)
		}

		return nil
	}

	mutating func visit(_ node: GroupExpr) -> TypeDef? {
		if let type = visit(node) {
			define(node, as: type)
			return type
		} else {
			error(node, "Unable to determine type")
		}
	}

	mutating func visit(_ node: StmtSyntax) -> TypeDef? {
		nil
	}

	mutating func visit(_ node: IfStmtSyntax) -> TypeDef? {
		let condDef = visit(node.condition)

		if condDef?.name != "Bool" {
			error(node.condition, "must be not bool")
		}

		visit(node.body)

		return nil
	}

	mutating func visit(_ node: UnaryOperator) -> TypeDef? {
		nil
	}

	mutating func visit(_ node: VarDeclSyntax) -> TypeDef? {
		let declDef = visit(node.typeDecl)
		let exprDef = visit(node.expr)

		if let declDef, !declDef.assignable(from: exprDef) {
			error(exprDef, "not assignable to \(declDef.name)")
		}

		define(node.variable, as: exprDef)

		return exprDef
	}

	mutating func visit(_ node: AssignmentExpr) -> TypeDef? {
		guard let receiverDef = visit(node.lhs) else {
			error(node.lhs, "Unable to determine type")
			return nil
		}

		guard let exprDef = visit(node.rhs) else {
			error(node.rhs, "Unable to determine type")
			return nil
		}

		if receiverDef.assignable(from: exprDef) {
			return receiverDef
		} else {
			error(node.rhs, "not assignable to \(receiverDef.name)")
			return nil
		}
	}

	mutating func visit(_ node: CallExprSyntax) -> TypeDef? {
		let calleeDef = visit(node.callee)
		// This is gonna take some work.

		return nil
	}

	mutating func visit(_ node: InitDeclSyntax) -> TypeDef? {
		visit(node.body)

		return nil // We can always assume this is the enclosing class
	}

	mutating func visit(_ node: BlockStmtSyntax) -> TypeDef? {
		for decl in node.decls {
			visit(decl)
		}

		return nil
	}

	mutating func visit(_ node: WhileStmtSyntax) {

	}

	mutating func visit(_ node: BinaryOperatorSyntax) {

	}

	mutating func visit(_ node: ParameterListSyntax) {

	}

	mutating func visit(_ node: ArgumentListSyntax) {

	}

	mutating func visit(_ node: ArrayLiteralSyntax) {
	}

	mutating func visit(_ node: IdentifierSyntax) {

	}

	mutating func visit(_ node: ReturnStmtSyntax) {

	}

	mutating func visit(_ node: ExprStmtSyntax) {

	}

	mutating func visit(_ node: PropertyAccessExpr) {

	}

	mutating func visit(_ node: LiteralExprSyntax) {

	}

	mutating func visit(_ node: UnaryExprSyntax) -> TypeDef? {
	let exprDef = visit(node.rhs)

		switch node.op.kind {
		case .bang:
			if exprDef.name != "Bool" {
				error(node, "can't negate \(exprDef.name)")
				return nil
			}

			return .bool
		case .minus:
			if exprDef.name != "Int" {
				error(node, "can't negate \(exprDef.name)")
				return nil
			}

			return .int
		}

		return nil


	}

	mutating func visit(_ node: ErrorSyntax) {

	}

	mutating func visit(_ node: ClassDeclSyntax) {

	}

	mutating func visit(_ node: BinaryExprSyntax) {
	}

	mutating func visit(_ node: IntLiteralSyntax) {
		define(node, as: .int)
	}

	mutating func visit(_ node: FunctionDeclSyntax) {

	}

	mutating func visit(_ node: VariableExprSyntax) {

	}

	mutating func visit(_ node: StringLiteralSyntax) {
		define(node, as: .string)
	}
}
