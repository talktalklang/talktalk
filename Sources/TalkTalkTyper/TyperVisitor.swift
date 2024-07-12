import TalkTalkSyntax

public class Results {
	public var errors: [TypeError] = []
	public var warnings: [String] = []
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

class Scope {
	var parent: Scope?
	var locals: [String: TypeDef] = [:]

	init(parent: Scope? = nil) {
		self.parent = parent
	}

	func lookup(identifier: String) -> TypeDef? {
		locals[identifier] ?? parent?.lookup(identifier: identifier)
	}
}

struct TyperVisitor: ASTVisitor {
	let ast: ProgramSyntax
	var results: Results = .init()
	var scopes: [Scope] = [Scope()]
	var currentScope: Scope {
		scopes.last!
	}

	mutating func withScope(perform: (inout TyperVisitor) -> Void) {
		let scope = Scope(parent: currentScope)
		var copy = self
		copy.scopes.append(scope)
		perform(&copy)
	}

	mutating func define(_ node: any Syntax, as typedef: TypeDef) {
		results.typedefs[node.position ..< node.position + node.length] = typedef
	}

	mutating func define(_ name: String, as typedef: TypeDef) {
		currentScope.locals[name] = typedef
	}

	mutating func error(_ node: any Syntax, _ msg: String, def: TypeDef? = nil) {
		results.errors.append(.init(syntax: node, message: msg, def: def))
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

	// MARK: Visits

	mutating func visit(_ node: ProgramSyntax) -> TypeDef? {
		for decl in node.decls {
			_ = decl.accept(&self)
		}

		return nil
	}

	mutating func visit(_ node: GroupExpr) -> TypeDef? {
		if let type = visit(node.expr) {
			define(node, as: type)
			return type
		} else {
			error(node, "Unable to determine type")
			return nil
		}
	}

	mutating func visit(_: StmtSyntax) -> TypeDef? {
		nil
	}

	mutating func visit(_ node: IfStmtSyntax) -> TypeDef? {
		let condDef = visit(node.condition)

		if condDef?.name != "Bool" {
			error(node.condition, "must be not bool")
		}

		withScope {
			_ = $0.visit(node.body)
		}

		return nil
	}

	mutating func visit(_: UnaryOperator) -> TypeDef? {
		nil
	}

	mutating func visit(_ node: TypeDeclSyntax) -> TypeDef? {
		TypeDef(name: node.name.lexeme, definition: node)
	}

	mutating func visit(_ node: VarDeclSyntax) -> TypeDef? {
		guard let expr = node.expr, let exprDef = visit(expr) else {
			error(node, "unable to determine expression type")
			return nil
		} // TODO: handle no expr case

		if let typeDecl = node.typeDecl,
		   let declDef = visit(typeDecl),
		   !declDef.assignable(from: exprDef)
		{
			error(node.variable, "not assignable to \(declDef.name)")
			return nil
		}

		define(node.variable, as: exprDef)
		define(node.variable.lexeme, as: exprDef)

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
			define(node.lhs, as: exprDef)
			return receiverDef
		} else {
			error(
				node.rhs,
				"not assignable to `\(node.lhs.description)`, expected \(receiverDef.name)",
				def: receiverDef
			)
			return nil
		}
	}

	mutating func visit(_: CallExprSyntax) -> TypeDef? {
		// let calleeDef = visit(node.callee)
		// This is gonna take some work.

		return nil
	}

	mutating func visit(_ node: InitDeclSyntax) -> TypeDef? {
		withScope {
			_ = $0.visit(node.body)
		}

		return nil // We can always assume this is the enclosing class
	}

	mutating func visit(_ node: BlockStmtSyntax) -> TypeDef? {
		withScope {
			for decl in node.decls {
				_ = decl.accept(&$0)
			}
		}

		return nil
	}

	mutating func visit(_ node: WhileStmtSyntax) -> TypeDef? {
		_ = visit(node.condition)

		withScope {
			_ = $0.visit(node.body)
		}

		// TODO: Validate condition is bool
		return nil
	}

	mutating func visit(_: BinaryOperatorSyntax) -> TypeDef? {
		nil
	}

	mutating func visit(_: ParameterListSyntax) -> TypeDef? {
		// TODO: handle type decls
		return nil
	}

	mutating func visit(_ node: ArgumentListSyntax) -> TypeDef? {
		for argument in node.arguments {
			_ = visit(argument)
			// TODO: Validate
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

		return .array(firstElemDef, from: firstElemDef.definition)
	}

	mutating func visit(_: IdentifierSyntax) -> TypeDef? {
		nil
	}

	mutating func visit(_ node: ReturnStmtSyntax) -> TypeDef? {
		_ = visit(node.value)
		return nil
	}

	mutating func visit(_ node: ExprStmtSyntax) -> TypeDef? {
		_ = visit(node.expr)
		return nil // Statements dont have types
	}

	mutating func visit(_ node: PropertyAccessExpr) -> TypeDef? {
		let receiverDef = visit(node.receiver)
		let propertyDef = visit(node.property)
		// TODO:
		return nil
	}

	mutating func visit(_ node: LiteralExprSyntax) -> TypeDef? {
		switch node.kind {
		case .nil: TypeDef(name: "Nil", definition: node)
		case .true: .bool(from: node)
		case .false: .bool(from: node)
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

			return .bool(from: node)
		case .minus:
			if exprDef.name != "Int" {
				error(node, "can't negate \(exprDef.name)")
				return nil
			}

			return .int(from: node.rhs)
		}
	}

	mutating func visit(_ node: ErrorSyntax) -> TypeDef? {
		TypeDef(name: "Error", definition: node)
	}

	mutating func visit(_: ClassDeclSyntax) -> TypeDef? {
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

		guard lhsDef.name == rhsDef.name else {
			error(node.op, "not the same type")
			return nil
		}

		// TODO: handle non-bool case
		return .bool(from: node.op)
	}

	mutating func visit(_ node: IntLiteralSyntax) -> TypeDef? {
		.int(from: node)
	}

	mutating func visit(_ node: FunctionDeclSyntax) -> TypeDef? {
		withScope {
			_ = $0.visit(node.body)
		}

		let returnDefs: [TypeDef] = node.body.decls.compactMap { decl -> TypeDef? in
			guard let stmt = decl.as(ReturnStmtSyntax.self) else {
				return nil
			}

			return visit(stmt.value)
		}

		// TODO: validate these match
		return returnDefs.first
	}

	mutating func visit(_ node: VariableExprSyntax) -> TypeDef? {
		currentScope.lookup(identifier: node.name.lexeme)
	}

	mutating func visit(_ node: StringLiteralSyntax) -> TypeDef? {
		return .string(from: node)
	}
}
