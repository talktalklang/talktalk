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

	mutating func visit(_ node: any Expr) -> TypeDef? {
		node.accept(&self)
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
			return nil
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

	mutating func visit(_ node: TypeDeclSyntax) -> TypeDef? {
		nil
	}

	mutating func visit(_ node: VarDeclSyntax) -> TypeDef? {
		let exprDef = visit(node.expr!)! // TODO: handle no expr case

		if let typeDecl = node.typeDecl, let declDef = visit(typeDecl), !declDef.assignable(from: exprDef) {
			error(node, "not assignable to \(declDef.name)")
			return nil
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

		return nil  // We can always assume this is the enclosing class
	}

	mutating func visit(_ node: BlockStmtSyntax) -> TypeDef? {
		for decl in node.decls {
			_ = decl.accept(&self)
		}

		return nil
	}

	mutating func visit(_ node: WhileStmtSyntax) -> TypeDef? {
		visit(node.condition)
		visit(node.body)
		return nil
	}

	mutating func visit(_ node: BinaryOperatorSyntax) -> TypeDef? {
		nil
	}

	mutating func visit(_ node: ParameterListSyntax) -> TypeDef? {
		// TODO: handle type decls
		return nil
	}

	mutating func visit(_ node: ArgumentListSyntax) -> TypeDef? {
		for argument in node.arguments {
			visit(argument)
		}

		return nil
	}

	mutating func visit(_ node: ArrayLiteralSyntax) -> TypeDef? {
		if node.elements.isEmpty {
			return nil
		}

		let elemDefs = node.elements.arguments.compactMap {
			visit($0)
		}

		// TODO: Check taht they match or add heterogenous arrays who knows
		let firstElemDef = elemDefs[0]

		return .array(firstElemDef)
	}

	mutating func visit(_ node: IdentifierSyntax) -> TypeDef? {
		nil
	}

	mutating func visit(_ node: ReturnStmtSyntax) -> TypeDef? {
		visit(node.value)
		return nil
	}

	mutating func visit(_ node: ExprStmtSyntax) -> TypeDef? {
		visit(node.expr)
		return nil // Statements dont have types
	}

	mutating func visit(_ node: PropertyAccessExpr) -> TypeDef? {
		let receiverDef = visit(node.receiver)
		let propertyDef = visit(node.property)
		// TODO:
		return nil
	}

	mutating func visit(_ node: LiteralExprSyntax) -> TypeDef?{
		switch node.kind {
		case .nil: TypeDef(name: "Nil")
		case .true: .bool
		case .false: .bool
		}
	}

	mutating func visit(_ node: UnaryExprSyntax) -> TypeDef? {
		guard let exprDef = visit(node.rhs) else {
			error(node.rhs, "could not determine type")
			return nil
		}

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

	mutating func visit(_ node: ErrorSyntax) -> TypeDef? {
		TypeDef(name: "Error")
	}

	mutating func visit(_ node: ClassDeclSyntax) -> TypeDef?{
		nil // At some point it'd be cool to have like a meta type
	}

	mutating func visit(_ node: BinaryExprSyntax) -> TypeDef? {
		guard let lhsDef = visit(node.lhs) else {
			error(node.lhs, "unable to determine type")
			return nil
		}

		guard let rhsDef = visit(node.rhs) else {
			error(node.rhs, "unable to determine type")
			return nil
		}

		guard lhsDef == rhsDef else {
			error(node.op, "not the same type")
			return nil
		}

		// TODO: handle non-bool case
		return .bool

	}

	mutating func visit(_ node: IntLiteralSyntax) -> TypeDef? {
		.int
	}

	mutating func visit(_ node: FunctionDeclSyntax) -> TypeDef? {
		visit(node.body)

		let returnDefs: [TypeDef] = node.body.decls.compactMap { (decl) -> TypeDef? in
			guard let stmt = decl.as(ReturnStmtSyntax.self) else {
				return nil
			}

			return visit(stmt.value)
		}

		// TODO: validate these match
		return returnDefs.first
	}

	mutating func visit(_ node: VariableExprSyntax) -> TypeDef? {
		nil // todo
	}

	mutating func visit(_ node: StringLiteralSyntax) -> TypeDef? {
		return .string
	}
}
