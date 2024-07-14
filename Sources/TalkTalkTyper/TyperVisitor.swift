import TalkTalkSyntax

public class Results {
	public var errors: [TypeError] = []
	public var warnings: [String] = []
	var typedefs: [Range<Int>: TypedValue] = [:]

	public func typedef(line: Int, column: Int, in source: String) -> TypedValue? {
		// TODO: optimize
		for (range, typedef) in typedefs {
			if range.contains(source.position(line: line, column: column)) {
				return typedef
			}
		}

		return nil
	}

	public func typedef(at position: Int) -> TypedValue? {
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
	var locals: [String: TypedValue] = [:]
	var types: [String: ValueType] = [:]

	init(parent: Scope? = nil) {
		self.parent = parent
	}

	var depth: Int {
		(parent?.depth ?? -1) + 1
	}

	func lookup(identifier: String) -> TypedValue? {
		locals[identifier] ?? parent?.lookup(identifier: identifier)
	}

	func lookup(type: String) -> ValueType? {
		types[type] ?? parent?.lookup(type: type)
	}
}

struct TyperVisitor: ASTVisitor {
	var results: Results = .init()

	mutating func define(_ node: any Syntax, as typedef: TypedValue, ref _: (any Syntax)? = nil) {
		results.typedefs[node.position ..< node.position + node.length] = typedef
	}

	mutating func error(_ node: any Syntax, _ msg: String, value: TypedValue? = nil) {
		results.errors.append(
			.init(
				syntax: node,
				message: msg,
				definition: value
			)
		)
	}

	mutating func returnType(from block: BlockStmtSyntax, context: Context) -> TypedValue? {
		// TODO: Validate
		var results: [TypedValue] = []
		for decl in block.decls {
			if let typedValue = decl.accept(&self, context: context) {
				results.append(typedValue)
			}
		}

		return results.last
	}

	mutating func visit(_ node: IfExprSyntax, context: Context) -> TypedValue? {
		// TODO: Validate this is a bool
		visit(node.condition, context: context)


		guard let lhs = returnType(from: node.thenBlock, context: context) else {
			error(node.thenBlock, "Unable to determine type")
			return nil
		}

		guard let rhs = returnType(from: node.elseBlock, context: context) else {
			error(node.elseBlock, "Unable to determine type")
			return nil
		}

		if lhs.type != rhs.type {
			error(node, "If expressions must return the same type from both branches")
			return nil
		}

		return TypedValue(
			type: lhs.type,
			definition: node
		)
	}

	mutating func visit(_ node: any Expr, context: Context) -> TypedValue? {
		node.accept(&self, context: context)
	}

	mutating func visit(ast: any Syntax, context: Context) -> Results {
		results = .init()

		for builtin in ValueType.builtins {
			context.define(type: builtin)
		}

		_ = ast.accept(&self, context: context)
		return results
	}

	// MARK: Visits

	mutating func visit(_ node: PropertyDeclSyntax, context: Context) -> TypedValue? {
		let name = node.name.lexeme
		guard let type = visit(node.typeDecl, context: context) else {
			error(node.typeDecl, "could not determine type")
			return nil
		}

		let typedValue = TypedValue(
			type: type.type,
			definition: node,
			ref: type
		)

		do {
			try context.define(member: name, as: typedValue, at: node)
		} catch {
			return nil
		}

		return .void(node)
	}

	mutating func visit(_ node: ProgramSyntax, context: Context) -> TypedValue? {
		for decl in node.decls {
			_ = decl.accept(&self, context: context)
		}

		return nil
	}

	mutating func visit(_ node: GroupExpr, context: Context) -> TypedValue? {
		if let type = visit(node.expr, context: context) {
			define(node, as: type)
			return type
		} else {
			error(node, "Unable to determine type")
			return nil
		}
	}

	mutating func visit(_: StmtSyntax, context _: Context) -> TypedValue? {
		nil
	}

	mutating func visit(_ node: IfStmtSyntax, context: Context) -> TypedValue? {
		guard let condDef = visit(node.condition, context: context) else {
			error(node, "type not able to be determined")
			return nil
		}

		if condDef.type != .bool {
			error(node.condition, "must be not bool")
		}

		context.withScope {
			_ = visit(node.body, context: $0)
		}

		return nil
	}

	mutating func visit(_: UnaryOperator, context _: Context) -> TypedValue? {
		nil
	}

	mutating func visit(_ node: TypeDeclSyntax, context: Context) -> TypedValue? {
		guard let type = context.lookup(type: node.name.lexeme) else {
			error(node, "unknown type")
			return nil
		}

		return TypedValue(type: type, definition: node)
	}

	mutating func visit(_ node: VarDeclSyntax, context: Context) -> TypedValue? {
		guard let expr = node.expr,
		      let exprDef = visit(expr, context: context)
		else {
			error(node, "unable to determine expression type")
			return nil
		} // TODO: handle no expr case

		if let typeDecl = node.typeDecl,
		   let declDef = visit(typeDecl, context: context),
		   !declDef.assignable(from: exprDef)
		{
			error(node.variable, "not assignable to \(declDef.type.description)")
			return nil
		}

		let typedValue = TypedValue(
			type: exprDef.type,
			definition: node.variable,
			ref: exprDef
		)

		define(node.variable, as: typedValue)
		context.define(node.variable, as: typedValue)

		return .void(node)
	}

	mutating func visit(_ node: AssignmentExpr, context: Context) -> TypedValue? {
		guard let receiverDef = visit(node.lhs, context: context) else {
			error(node.lhs, "Unable to determine type of `\(node.lhs.description)`")
			return nil
		}

		guard let exprDef = visit(node.rhs, context: context) else {
			error(node.rhs, "Unable to determine type of `\(node.rhs.description)`")
			return nil
		}

		if receiverDef.assignable(from: exprDef) {
			define(node.lhs, as: exprDef, ref: exprDef.definition)
			define(node.rhs, as: exprDef)
			return receiverDef
		} else {
			define(node.lhs, as: receiverDef)
			error(
				node.rhs,
				"\(exprDef.type.description) not assignable to `\(node.lhs.description)`, expected \(receiverDef.type.description)",
				value: TypedValue(
					type: receiverDef.type,
					definition: node.lhs,
					ref: context.lookup(node.lhs)
				)
			)
			return nil
		}
	}

	mutating func visit(_ node: CallExprSyntax, context: Context) -> TypedValue? {
		// Handle function calls
		if let def = visit(node.callee, context: context),
		   let returns = def.type.returns?.value
		{
			define(node.callee, as: TypedValue(type: returns, definition: node))
			return TypedValue(type: returns, definition: node)
		}

		// Handle class constructor calls
		if let def = context.lookup(type: node.callee.description + ".Type"),
		   let returns = def.returns?.value
		{
			define(node.callee, as: TypedValue(type: returns, definition: node.callee))
			return returns.bind(node.callee)
		}

		return nil
	}

	mutating func visit(_ node: InitDeclSyntax, context: Context) -> TypedValue? {
		context.withScope {
			_ = visit(node.body, context: $0)
		}

		return nil // We can always assume this is the enclosing class
	}

	mutating func visit(_ node: BlockStmtSyntax, context: Context) -> TypedValue? {
		context.withScope {
			for decl in node.decls {
				_ = decl.accept(&self, context: $0)
			}
		}

		return .void(node)
	}

	mutating func visit(_ node: WhileStmtSyntax, context: Context) -> TypedValue? {
		_ = visit(node.condition, context: context)

		context.withScope {
			_ = visit(node.body, context: $0)
		}

		// TODO: Validate condition is bool
		return nil
	}

	mutating func visit(_: BinaryOperatorSyntax, context _: Context) -> TypedValue? {
		nil
	}

	mutating func visit(_: ParameterListSyntax, context _: Context) -> TypedValue? {
		// TODO: handle type decls
		return nil
	}

	mutating func visit(_ node: ArgumentListSyntax, context: Context) -> TypedValue? {
		for argument in node.arguments {
			_ = visit(argument, context: context)
			// TODO: Validate
		}

		return nil
	}

	mutating func visit(_ node: ArrayLiteralSyntax, context: Context) -> TypedValue? {
		if node.elements.isEmpty {
			return nil
		}

		let elemDefs = node.elements.arguments.compactMap {
			visit($0, context: context)
		}

		// TODO: Check taht they match or add heterogenous arrays who knows
		let firstElemDef = elemDefs[0]

		define(node, as: .array(firstElemDef.type, from: node))

		return .array(firstElemDef.type, from: node)
	}

	mutating func visit(_ node: IdentifierSyntax, context: Context) -> TypedValue? {
		return context.lookup(node)
	}

	mutating func visit(_ node: ReturnStmtSyntax, context: Context) -> TypedValue? {
		return visit(node.value, context: context)
	}

	mutating func visit(_ node: ExprStmtSyntax, context: Context) -> TypedValue? {
		_ = visit(node.expr, context: context)
		return .void(node) // Statements dont have types... fow now?????
	}

	mutating func visit(_ node: PropertyAccessExpr, context: Context) -> TypedValue? {
		guard let receiverDef = visit(node.receiver, context: context) else {
			error(node.receiver, "could not determine type")
			return nil
		}

		if let property = receiverDef.type.property(named: node.property.lexeme) {
			define(node.property, as: property.type, ref: property.definition)
			context.define(node.property, as: property.type)
			return property.type
		}

		return nil
	}

	mutating func visit(_ node: LiteralExprSyntax, context _: Context) -> TypedValue? {
		let type: ValueType = switch node.kind {
		case .nil: .nil
		case .true: .bool
		case .false: .bool
		}

		define(node, as: type.bind(node))
		return type.bind(node)
	}

	mutating func visit(_ node: UnaryExprSyntax, context: Context) -> TypedValue? {
		guard let exprDef = visit(node.rhs, context: context) else {
			error(node.rhs, "could not determine type")
			return nil
		}

		switch node.op.kind {
		case .bang:
			if exprDef.type != .bool {
				error(node, "can't negate \(exprDef)")
				return nil
			}

			define(node, as: .bool(from: node))

			return .bool(from: node)
		case .minus:
			if exprDef.type != .int {
				error(node, "can't negate \(exprDef)")
				return nil
			}

			define(node, as: .int(from: node))

			return .int(from: node)
		}
	}

	mutating func visit(_ node: ErrorSyntax, context _: Context) -> TypedValue? {
		ValueType(id: -99, name: "Error: \(node.description)", definition: node).bind(node)
	}

	mutating func visit(_ node: ClassDeclSyntax, context: Context) -> TypedValue? {
		let properties = context.withClassScope {
			_ = visit(node.body, context: $0)
		}

		let name = node.name.lexeme

		let classType = ValueType(
			id: (name + ".Type").hashValue,
			name: name + ".Type",
			definition: node,
			properties: properties,
			returns: { t in
				ValueType(
					id: name.hashValue,
					name: name,
					definition: node,
					ofType: { _ in t }
				)
			}
		)

		// Store the class in the scope so we can call it to instantiate
		context.define(type: classType)

		define(
			node.name,
			as: classType.bind(node.name)
		)

		return classType.bind(node.name)
	}

	mutating func visit(_ node: BinaryExprSyntax, context: Context) -> TypedValue? {
		guard let lhsDef = visit(node.lhs, context: context) else {
			error(node.lhs, "unable to determine type")
			return nil
		}

		guard let rhsDef = visit(node.rhs, context: context) else {
			error(node.rhs, "unable to determine type")
			return nil
		}

		guard lhsDef.type == rhsDef.type else {
			error(node.op, "not the same type")
			return nil
		}

		if [
			.andAnd,
			.pipePipe,
			.less,
			.lessEqual,
			.greater,
			.greaterEqual,
			.equalEqual,
			.bangEqual,
		].contains(node.op.kind) {
			define(node, as: .bool(from: node))
			return .bool(from: node)
		} else {
			define(node, as: lhsDef)
			return lhsDef
		}
	}

	mutating func visit(_ node: IntLiteralSyntax, context _: Context) -> TypedValue? {
		define(node, as: .int(from: node))

		return .int(from: node)
	}

	mutating func visit(_ node: FunctionDeclSyntax, context: Context) -> TypedValue? {
		let declDef: ValueType? = if let typeDecl = node.typeDecl,
		                             let type = visit(typeDecl, context: context)
		{
			ValueType.function(type.type)
		} else {
			nil
		}

		_ = visit(node.body, context: context)

		var lastReturnDef: ValueType?
		let returnDefs: [TypedValue] = node.body.decls.compactMap { decl -> TypedValue? in
			guard let stmt = decl.as(ReturnStmtSyntax.self) else {
				return nil
			}

			guard let def = visit(stmt, context: context) else {
				if declDef == nil {
					error(stmt.value, "could not determine return type")
				}

				return nil
			}

			if let lastReturnDef, !lastReturnDef.assignable(from: def.type) {
				error(stmt.value, "Function cannot return different types")
				return nil
			}

			if let declDef, !declDef.returns!.value.assignable(from: def.type) {
				error(stmt.value, "Not assignable to \(declDef.returns!.value)")
				return nil
			}

			lastReturnDef = def.type
			define(stmt.value, as: def, ref: stmt)

			return def
		}

		let returnDef = returnDefs.first

		let typedef = returnDef?.type ?? .void

		let typedValue = TypedValue(
			type: .function(declDef?.returns?.value ?? typedef),
			definition: node.name,
			ref: returnDef
		)

		if context.currentClass != nil {
			define(node, as: typedValue)

			// This only throws when there's no class
			try! context.define(member: node.name.lexeme, as: typedValue, at: node)
		} else {
			define(node, as: typedValue)
			context.define(node.name, as: typedValue)
		}

		return typedValue
	}

	mutating func visit(_ node: VariableExprSyntax, context: Context) -> TypedValue? {
		visit(node.name, context: context)
	}

	mutating func visit(_ node: StringLiteralSyntax, context _: Context) -> TypedValue? {
		define(node, as: .string(from: node))
		return .string(from: node)
	}
}
