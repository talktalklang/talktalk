import TalkTalkSyntax

class TyperVisitor: ASTVisitor {
	var bindings: Bindings = .init(ast: ProgramSyntax.main)

	init(ast: any Syntax) {
		self.bindings = .init(ast: ast)
	}

	func define(_ node: any Syntax, as typedef: TypedValue, ref _: (any Syntax)? = nil) {
		bindings.define(node, as: typedef)
	}

	func error(_ node: any Syntax, _ msg: String, value: TypedValue? = nil) {
		bindings.errors.append(
			.init(
				syntax: node,
				message: msg,
				definition: value
			)
		)
	}

	func returnType(from block: BlockStmtSyntax, context: Context) -> TypedValue? {
		// TODO: Validate
		var results: [TypedValue] = []
		for decl in block.decls {
			if let typedValue = decl.accept(self, context: context) {
				results.append(typedValue)
			}
		}

		return results.last
	}

	func visit(_ node: IfExprSyntax, context: Context) -> TypedValue? {
		// TODO: Validate this is a bool
		_ = visit(node.condition, context: context)

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
			definition: node,
			status: .defined
		)
	}

	func visit(_ node: any Expr, context: Context) -> TypedValue? {
		node.accept(self, context: context)
	}

	func visit(ast: any Syntax, context: Context) -> Bindings {
		bindings = .init(ast: ast)

		for builtin in ValueType.builtins {
			context.define(type: builtin)
		}

		_ = ast.accept(self, context: context)
		return bindings
	}

	// MARK: Visits

	func visit(_ node: PropertyDeclSyntax, context: Context) -> TypedValue? {
		let name = node.name.lexeme
		guard let type = visit(node.typeDecl, context: context) else {
			error(node.typeDecl, "could not determine type")
			return nil
		}

		let typedValue = TypedValue(
			type: type.type,
			definition: node,
			ref: type,
			status: .declared
		)

		do {
			try context.define(member: name, as: typedValue, at: node)
		} catch {
			return nil
		}

		return .void(node)
	}

	func visit(_ node: ProgramSyntax, context: Context) -> TypedValue? {
		for decl in node.decls {
			_ = decl.accept(self, context: context)
		}

		return nil
	}

	func visit(_ node: GroupExpr, context: Context) -> TypedValue? {
		if let type = visit(node.expr, context: context) {
			define(node, as: type)
			return type
		} else {
			error(node, "Unable to determine type")
			return nil
		}
	}

	func visit(_: StmtSyntax, context _: Context) -> TypedValue? {
		nil
	}

	func visit(_ node: IfStmtSyntax, context: Context) -> TypedValue? {
		guard let condDef = visit(node.condition, context: context) else {
			error(node, "type not able to be determined")
			return nil
		}

		if condDef.type != .bool {
			error(node.condition, "must be not bool")
		}

		_ = visit(node.body, context: context)

		return nil
	}

	func visit(_: UnaryOperator, context _: Context) -> TypedValue? {
		nil
	}

	func visit(_ node: TypeDeclSyntax, context: Context) -> TypedValue? {
		guard let type = context.lookup(type: node.name.lexeme) else {
			error(node, "unknown type")
			return nil
		}

		return TypedValue(type: type, definition: node, status: .declared)
	}

	func visit(_ node: VarDeclSyntax, context: Context) -> TypedValue? {
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
			definition: node,
			ref: exprDef,
			status: .defined
		)

		define(node, as: typedValue)
		context.define(node, as: typedValue)

		return .void(node)
	}

	func visit(_ node: LetDeclSyntax, context: Context) -> TypedValue? {
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
			definition: node,
			ref: exprDef,
			status: .defined
		)

		define(node.variable, as: typedValue)
		context.define(node.variable, as: typedValue)

		return .void(node)
	}

	func visit(_ node: AssignmentExpr, context: Context) -> TypedValue? {
		guard let receiverDef = visit(node.lhs, context: context) else {
			error(node.lhs, "Unable to determine type of `\(node.lhs.description)`")
			return nil
		}

		guard let exprDef = visit(node.rhs, context: context) else {
			error(node.rhs, "Unable to determine type of `\(node.rhs.description)`")
			return nil
		}

		if let def = receiverDef.definition.as(LetDeclSyntax.self), receiverDef.status == .defined {
			error(node.rhs, "Cannot reassign let variable: `\(def.variable)`")
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
					ref: context.lookup(node.lhs),
					status: .declared
				)
			)
			return nil
		}
	}

	func visit(_ node: CallExprSyntax, context: Context) -> TypedValue? {
		// Handle function calls
		if let def = visit(node.callee, context: context),
		   let returns = def.type.returns?.value
		{
			define(node.callee, as: TypedValue(type: returns, definition: node, status: .defined))
			return TypedValue(type: returns, definition: node, status: .defined)
		}

		// Handle class constructor calls
		if let def = context.lookup(type: node.callee.description + ".Type"),
		   let returns = def.returns?.value
		{
			define(node.callee, as: TypedValue(type: returns, definition: node.callee, status: .defined))
			return returns.bind(node.callee)
		}

		return .init(type: .tbd, definition: node, status: .declared)
	}

	func visit(_ node: InitDeclSyntax, context: Context) -> TypedValue? {
		context.withScope {
			_ = visit(node.body, context: $0)
		}

		return nil // We can always assume this is the enclosing class
	}

	func visit(_ node: BlockStmtSyntax, context: Context) -> TypedValue? {
		context.withScope {
			for decl in node.decls {
				_ = decl.accept(self, context: $0)
			}
		}

		return .void(node)
	}

	func visit(_ node: WhileStmtSyntax, context: Context) -> TypedValue? {
		_ = visit(node.condition, context: context)

		context.withScope {
			_ = visit(node.body, context: $0)
		}

		// TODO: Validate condition is bool
		return nil
	}

	func visit(_: BinaryOperatorSyntax, context _: Context) -> TypedValue? {
		nil
	}

	func visit(_ node: ParameterListSyntax, context: Context) -> TypedValue? {
		// TODO: handle type decls
		for parameter in node.parameters {
			context.define(parameter, as: .tbd, status: .declared)
		}

		return nil
	}

	func visit(_ node: ArgumentListSyntax, context: Context) -> TypedValue? {
		for argument in node.arguments {
			_ = visit(argument, context: context)
			// TODO: Validate
		}

		return nil
	}

	func visit(_ node: ArrayLiteralSyntax, context: Context) -> TypedValue? {
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

	func visit(_ node: IdentifierSyntax, context: Context) -> TypedValue? {
		return context.lookup(node)
	}

	func visit(_ node: ReturnStmtSyntax, context: Context) -> TypedValue? {
		return visit(node.value, context: context)
	}

	func visit(_ node: ExprStmtSyntax, context: Context) -> TypedValue? {
		_ = visit(node.expr, context: context)
		return .void(node) // Statements dont have types... fow now?????
	}

	func visit(_ node: PropertyAccessExpr, context: Context) -> TypedValue? {
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

	func visit(_ node: LiteralExprSyntax, context _: Context) -> TypedValue? {
		let type: ValueType = switch node.kind {
		case .nil: .nil
		case .true: .bool
		case .false: .bool
		}

		define(node, as: type.bind(node))
		return type.bind(node)
	}

	func visit(_ node: UnaryExprSyntax, context: Context) -> TypedValue? {
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

	func visit(_ node: ErrorSyntax, context _: Context) -> TypedValue? {
		ValueType(id: -99, name: "Error: \(node.description)", definition: node).bind(node)
	}

	func visit(_ node: ClassDeclSyntax, context: Context) -> TypedValue? {
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

	func visit(_ node: BinaryExprSyntax, context: Context) -> TypedValue? {
		guard var lhsDef = visit(node.lhs, context: context) else {
			error(node.lhs, "unable to determine type")
			return nil
		}

		guard var rhsDef = visit(node.rhs, context: context) else {
			error(node.rhs, "unable to determine type")
			return nil
		}

		if lhsDef.type == .tbd, rhsDef.type != .tbd {
			lhsDef = context.infer(from: rhsDef.type, to: lhsDef)!

			context.define(node.lhs, as: lhsDef)
			define(node.lhs, as: lhsDef)
		}

		if rhsDef.type == .tbd, lhsDef.type != .tbd {
			rhsDef = context.infer(from: lhsDef.type, to: rhsDef)!

			context.define(node.rhs, as: rhsDef)
			define(node.rhs, as: rhsDef)
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

	func visit(_ node: IntLiteralSyntax, context _: Context) -> TypedValue? {
		define(node, as: .int(from: node))

		return .int(from: node)
	}

	func visit(_ node: FunctionDeclSyntax, context: Context) -> TypedValue? {
		let declDef: ValueType? = if let typeDecl = node.typeDecl,
		                             let type = visit(typeDecl, context: context)
		{
			ValueType.function(type.type)
		} else {
			nil
		}

		_ = visit(node.parameters, context: context)
		_ = visit(node.body, context: context)

		var lastReturnDef: ValueType?
		let returnDefs: [TypedValue] = node.body.decls.compactMap { decl -> TypedValue? in
			guard let stmt = decl.as(ReturnStmtSyntax.self) else {
				return nil
			}

			guard var def = visit(stmt, context: context) else {
				return TypedValue(type: .tbd, definition: stmt, status: .declared)
			}

			if let declDef, !declDef.returns!.value.assignable(from: def.type) {
				if def.type == .tbd,
				   let returns = declDef.returns?.value,
				   let inferred = context.infer(from: returns, to: def)
				{
					def = inferred
					define(stmt.value, as: def)
				} else {
					error(stmt.value, "Not assignable to \(declDef.returns!.value)")
					return nil
				}
			}

			if let lastReturnDef, !lastReturnDef.assignable(from: def.type) {
				error(stmt.value, "Function cannot return different types")
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
			ref: returnDef,
			status: .defined
		)

		if context.currentClass != nil {
			define(node, as: typedValue)

			// This only throws when there's no class
			try! context.define(member: node.name.lexeme, as: typedValue, at: node)
		} else {
			define(node.name, as: typedValue)
			context.define(node.name, as: typedValue)
		}

		// Try to fill in parameters
		for parameter in node.parameters.parameters {
			if let typedValue = context.lookup(identifier: parameter.lexeme) {
				define(parameter, as: typedValue.type.bind(parameter, ref: typedValue))
				context.define(parameter, as: typedValue.type.bind(parameter, ref: typedValue))
			}
		}

		return typedValue
	}

	func visit(_ node: VariableExprSyntax, context: Context) -> TypedValue? {
		visit(node.name, context: context)
	}

	func visit(_ node: StringLiteralSyntax, context _: Context) -> TypedValue? {
		define(node, as: .string(from: node))
		return .string(from: node)
	}
}
