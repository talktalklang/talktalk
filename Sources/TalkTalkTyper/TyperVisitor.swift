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

	struct Context {
		var scopes: [Scope] = [Scope()]
		var currentScope: Scope {
			scopes.last!
		}

		mutating func withScope(perform: (inout Context) -> Void) {
			let scope = Scope(parent: currentScope)
			var copy = self
			copy.scopes.append(scope)
			perform(&copy)
		}

		func lookup(_ syntax: any Syntax) -> TypeDef? {
			currentScope.lookup(identifier: name(for: syntax))
		}

		mutating func define(_ syntax: any Syntax, as typedef: TypeDef) {
			currentScope.locals[name(for: syntax)] = typedef
		}

		func name(for syntax: any Syntax) -> String {
			switch syntax {
			case let syntax as VariableExprSyntax:
				syntax.name.lexeme
			case let syntax as IdentifierSyntax:
				syntax.lexeme
			default:

				"NO NAME FOR \(syntax)"
			}
		}
	}

	mutating func define(_ node: any Syntax, as typedef: TypeDef) {
		results.typedefs[node.position ..< node.position + node.length] = typedef
	}

	mutating func error(_ node: any Syntax, _ msg: String, def: TypeDef? = nil) {
		results.errors.append(.init(syntax: node, message: msg, def: def))
	}

	func infer(type expr: Expr, context: inout Context) -> TypeDef? {
		results.typedef(at: expr.position)
	}

	mutating func visit(_ node: any Expr, context: inout Context) -> TypeDef? {
		node.accept(&self, context: &context)
	}

	mutating func check() -> Results {
		results = .init()
		var context = Context()
		_ = visit(ast, context: &context)
		return results
	}

	// MARK: Visits

	mutating func visit(_ node: ProgramSyntax, context: inout Context) -> TypeDef? {
		for decl in node.decls {
			_ = decl.accept(&self, context: &context)
		}

		return nil
	}

	mutating func visit(_ node: GroupExpr, context: inout Context) -> TypeDef? {
		if let type = visit(node.expr, context: &context) {
			define(node, as: type)
			return type
		} else {
			error(node, "Unable to determine type")
			return nil
		}
	}

	mutating func visit(_: StmtSyntax, context: inout Context) -> TypeDef? {
		nil
	}

	mutating func visit(_ node: IfStmtSyntax, context: inout Context) -> TypeDef? {
		let condDef = visit(node.condition, context: &context)

		if condDef?.name != "Bool" {
			error(node.condition, "must be not bool")
		}

		context.withScope {
			_ = visit(node.body, context: &$0)
		}

		return nil
	}

	mutating func visit(_: UnaryOperator, context: inout Context) -> TypeDef? {
		nil
	}

	mutating func visit(_ node: TypeDeclSyntax, context: inout Context) -> TypeDef? {
		TypeDef(name: node.name.lexeme, definition: node)
	}

	mutating func visit(_ node: VarDeclSyntax, context: inout Context) -> TypeDef? {
		guard let expr = node.expr, let exprDef = visit(expr, context: &context) else {
			error(node, "unable to determine expression type")
			return nil
		} // TODO: handle no expr case

		if let typeDecl = node.typeDecl,
		   let declDef = visit(typeDecl, context: &context),
		   !declDef.assignable(from: exprDef)
		{
			error(node.variable, "not assignable to \(declDef.name)")
			return nil
		}

		define(node.variable, as: exprDef)

		context.define(node.variable, as: exprDef)

		return exprDef
	}

	mutating func visit(_ node: AssignmentExpr, context: inout Context) -> TypeDef? {
		_ = visit(node.lhs, context: &context)

		guard let receiverDef = context.lookup(node.lhs) else {
			error(node.lhs, "Unknown variable: \(context.name(for: node.lhs))")
			return nil
		}

		guard let exprDef = visit(node.rhs, context: &context) else {
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

	mutating func visit(_: CallExprSyntax, context: inout Context) -> TypeDef? {
		// let calleeDef = visit(node.callee)
		// This is gonna take some work.

		return nil
	}

	mutating func visit(_ node: InitDeclSyntax, context: inout Context) -> TypeDef? {
		context.withScope {
			_ = visit(node.body, context: &$0)
		}

		return nil // We can always assume this is the enclosing class
	}

	mutating func visit(_ node: BlockStmtSyntax, context: inout Context) -> TypeDef? {
		context.withScope {
			for decl in node.decls {
				_ = decl.accept(&self, context: &$0)
			}
		}

		return nil
	}

	mutating func visit(_ node: WhileStmtSyntax, context: inout Context) -> TypeDef? {
		_ = visit(node.condition, context: &context)

		context.withScope {
			_ = visit(node.body, context: &$0)
		}

		// TODO: Validate condition is bool
		return nil
	}

	mutating func visit(_: BinaryOperatorSyntax, context: inout Context) -> TypeDef? {
		nil
	}

	mutating func visit(_: ParameterListSyntax, context: inout Context) -> TypeDef? {
		// TODO: handle type decls
		return nil
	}

	mutating func visit(_ node: ArgumentListSyntax, context: inout Context) -> TypeDef? {
		for argument in node.arguments {
			_ = visit(argument, context: &context)
			// TODO: Validate
		}

		return nil
	}

	mutating func visit(_ node: ArrayLiteralSyntax, context: inout Context) -> TypeDef? {
		if node.elements.isEmpty {
			return nil
		}

		let elemDefs = node.elements.arguments.compactMap {
			visit($0, context: &context)
		}

		// TODO: Check taht they match or add heterogenous arrays who knows
		let firstElemDef = elemDefs[0]

		return .array(firstElemDef, from: firstElemDef.definition)
	}

	mutating func visit(_: IdentifierSyntax, context: inout Context) -> TypeDef? {
		nil
	}

	mutating func visit(_ node: ReturnStmtSyntax, context: inout Context) -> TypeDef? {
		_ = visit(node.value, context: &context)
		return nil
	}

	mutating func visit(_ node: ExprStmtSyntax, context: inout Context) -> TypeDef? {
		_ = visit(node.expr, context: &context)
		return nil // Statements dont have types
	}

	mutating func visit(_ node: PropertyAccessExpr, context: inout Context) -> TypeDef? {
//		let receiverDef = visit(node.receiver, context: &context)
//		let propertyDef = visit(node.property, context: &context)
		// TODO:
		return nil
	}

	mutating func visit(_ node: LiteralExprSyntax, context: inout Context) -> TypeDef? {
		switch node.kind {
		case .nil: TypeDef(name: "Nil", definition: node)
		case .true: .bool(from: node)
		case .false: .bool(from: node)
		}
	}

	mutating func visit(_ node: UnaryExprSyntax, context: inout Context) -> TypeDef? {
		guard let exprDef = visit(node.rhs, context: &context) else {
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

	mutating func visit(_ node: ErrorSyntax, context: inout Context) -> TypeDef? {
		TypeDef(name: "Error", definition: node)
	}

	mutating func visit(_: ClassDeclSyntax, context: inout Context) -> TypeDef? {
		nil // At some point it'd be cool to have like a meta type
	}

	mutating func visit(_ node: BinaryExprSyntax, context: inout Context) -> TypeDef? {
		guard let lhsDef = visit(node.lhs, context: &context) else {
			error(node.lhs, "unable to determine type")
			return nil
		}

		guard let rhsDef = visit(node.rhs, context: &context) else {
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

	mutating func visit(_ node: IntLiteralSyntax, context: inout Context) -> TypeDef? {
		.int(from: node)
	}

	mutating func visit(_ node: FunctionDeclSyntax, context: inout Context) -> TypeDef? {
		let declDef: TypeDef? = if let typeDecl = node.typeDecl {
			TypeDef(name: "Function<\(typeDecl.name.lexeme)>", definition: node)
		} else {
			nil
		}

		context.withScope {
			_ = visit(node.body, context: &$0)
		}

		var lastReturnDef: TypeDef?
		let returnDefs: [TypeDef] = node.body.decls.compactMap { decl -> TypeDef? in
			guard let stmt = decl.as(ReturnStmtSyntax.self) else {
				return nil
			}

			guard let def = visit(stmt.value, context: &context) else {
				return nil
			}

			if let lastReturnDef, !lastReturnDef.assignable(from: def){
				error(def.definition, "Function cannot return different types")
				return nil
			}

			if let declDef, !declDef.returnDef().assignable(from: def) {
				error(stmt.value, "Not assignable to \(declDef.returnDef().name)")
				return nil
			}

			lastReturnDef = def

			return def
		}

		let returnDef = returnDefs.first

		let typedef = TypeDef(
			name: "Function<\(returnDef?.name ?? "Void")>",
			definition: node
		)

		let def = declDef ?? typedef

		define(node, as: def)
		context.define(node, as: def)

		// TODO: validate these match
		return declDef ?? typedef
	}

	mutating func visit(_ node: VariableExprSyntax, context: inout Context) -> TypeDef? {
		context.currentScope.lookup(identifier: node.name.lexeme)
	}

	mutating func visit(_ node: StringLiteralSyntax, context: inout Context) -> TypeDef? {
		return .string(from: node)
	}
}
