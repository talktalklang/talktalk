import TalkTalkSyntax

public class Results {
	public var errors: [TypeError] = []
	public var warnings: [String] = []
	var typedefs: [Range<Int>: TypedValue] = [:]

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

	func lookup(identifier: String) -> ValueType? {
		locals[identifier]?.type ?? parent?.lookup(identifier: identifier)
	}

	func lookup(type: String) -> ValueType? {
		types[type] ?? parent?.lookup(type: type)
	}
}

struct TyperVisitor: ASTVisitor {
	enum TypeVisitorError: Swift.Error {
		case notInClass
	}

	let ast: ProgramSyntax
	var results: Results = .init()

	class Context {
		var scopes: [Scope] = [Scope()]
		var classes: [
			[String: Property]
		] = []

		init(scopes: [Scope] = [Scope()]) {
			self.scopes = scopes
		}

		var currentScope: Scope {
			scopes.last!
		}

		// TODO: Handle depth issues
		func withScope<T>(perform: (Context) -> T) -> T {
			let scope = Scope(parent: currentScope)
			scopes.append(scope)
			return perform(self)
		}

		func withClassScope(perform: (Context) -> Void) -> [String: Property] {
			classes.append([:])
			defer {
				_ = self.classes.popLast()
			}

			perform(self)
			return currentClass!
		}

		var currentClass: [String: Property]? {
			get {
				classes.last
			}

			set {
				classes[classes.count - 1] = newValue!
			}
		}

		func lookup(_ syntax: any Syntax) -> ValueType? {
			currentScope.lookup(identifier: name(for: syntax))
		}

		func lookup(type: String) -> ValueType? {
			currentScope.lookup(type: type)
		}

		func define(_ syntax: any Syntax, as typedef: TypedValue) {
			currentScope.locals[name(for: syntax)] = typedef
		}

		func define(_ syntax: any Syntax, as type: ValueType) {
			currentScope.locals[name(for: syntax)] = TypedValue(type: type, definition: syntax)
		}

		func define(type: ValueType) {
			currentScope.types[type.name] = type
		}

		func define(member: String, as type: ValueType, at token: any Syntax) throws {
			guard currentClass != nil else {
				throw TypeVisitorError.notInClass
			}

			currentClass![member] = .init(
				name: member,
				type: type,
				definition: token
			)
		}

		func name(for syntax: any Syntax) -> String {
			switch syntax {
			case let syntax as VariableExprSyntax:
				syntax.name.lexeme
			case let syntax as IdentifierSyntax:
				syntax.lexeme
			case let syntax as FunctionDeclSyntax:
				syntax.name.lexeme
			default:

				"NO NAME FOR \(syntax)"
			}
		}
	}

	mutating func define(_ node: any Syntax, as typedef: ValueType, ref: (any Syntax)? = nil) {
		results.typedefs[node.position ..< node.position + node.length] = TypedValue(
			type: typedef,
			definition: node,
			ref: ref
		)
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

	mutating func visit(_ node: any Expr, context: Context) -> ValueType? {
		node.accept(&self, context: context)
	}

	mutating func check() -> Results {
		results = .init()
		let context = Context()

		context.define(type: .bool)
		context.define(type: .int)
		context.define(type: .string)
		context.define(type: .void)

		_ = visit(ast, context: context)
		return results
	}

	// MARK: Visits

	mutating func visit(_ node: PropertyDeclSyntax, context: Context) -> ValueType? {
		let name = node.name.lexeme
		guard let type = visit(node.typeDecl, context: context) else {
			error(node.typeDecl, "could not determine type")
			return nil
		}

		do {
			try context.define(member: name, as: type, at: node)
		} catch {
			return nil
		}

		return .void
	}

	mutating func visit(_ node: ProgramSyntax, context: Context) -> ValueType? {
		for decl in node.decls {
			_ = decl.accept(&self, context: context)
		}

		return nil
	}

	mutating func visit(_ node: GroupExpr, context: Context) -> ValueType? {
		if let type = visit(node.expr, context: context) {
			define(node, as: type)
			return type
		} else {
			error(node, "Unable to determine type")
			return nil
		}
	}

	mutating func visit(_: StmtSyntax, context _: Context) -> ValueType? {
		nil
	}

	mutating func visit(_ node: IfStmtSyntax, context: Context) -> ValueType? {
		let condDef = visit(node.condition, context: context)

		if condDef != .bool {
			error(node.condition, "must be not bool")
		}

		context.withScope {
			_ = visit(node.body, context: $0)
		}

		return nil
	}

	mutating func visit(_: UnaryOperator, context _: Context) -> ValueType? {
		nil
	}

	mutating func visit(_ node: TypeDeclSyntax, context: Context) -> ValueType? {
		guard let type = context.lookup(type: node.name.lexeme) else {
			error(node, "unknown type")
			return nil
		}

		return type
	}

	mutating func visit(_ node: VarDeclSyntax, context: Context) -> ValueType? {
		guard let expr = node.expr, let exprDef = visit(expr, context: context) else {
			error(node, "unable to determine expression type")
			return nil
		} // TODO: handle no expr case

		if let typeDecl = node.typeDecl,
		   let declDef = visit(typeDecl, context: context),
		   !declDef.assignable(from: exprDef)
		{
			error(node.variable, "not assignable to \(declDef.description)")
			return nil
		}

		define(node.variable, as: exprDef)
		context.define(node.variable, as: exprDef)

		return exprDef
	}

	mutating func visit(_ node: AssignmentExpr, context: Context) -> ValueType? {
		guard let receiverDef = visit(node.lhs, context: context) else {
			error(node.lhs, "Unable to determine type of `\(node.lhs.description)`")
			return nil
		}

		guard let exprDef = visit(node.rhs, context: context) else {
			error(node.rhs, "Unable to determine type of `\(node.rhs.description)`")
			return nil
		}

		if receiverDef.assignable(from: exprDef) {
			define(node.lhs, as: exprDef)
			return receiverDef
		} else {
			error(
				node.rhs,
				"\(exprDef.description) not assignable to `\(node.lhs.description)`, expected \(receiverDef.description)",
				value: .init(
					type: receiverDef,
					definition: receiverDef.definition,
					ref: receiverDef.ofType?.value.definition
				)
			)
			return nil
		}
	}

	mutating func visit(_ node: CallExprSyntax, context: Context) -> ValueType? {
		// Handle function calls
		if let def = visit(node.callee, context: context), let returns = def.returns?.value {
			return returns
		}

		// Handle class constructor calls
		if let def = context.lookup(type: node.callee.description + ".Type") {
			return def.returns!.value
		}

		return nil
	}

	mutating func visit(_ node: InitDeclSyntax, context: Context) -> ValueType? {
		context.withScope {
			_ = visit(node.body, context: $0)
		}

		return nil // We can always assume this is the enclosing class
	}

	mutating func visit(_ node: BlockStmtSyntax, context: Context) -> ValueType? {
		context.withScope {
			for decl in node.decls {
				_ = decl.accept(&self, context: $0)
			}
		}

		return .void
	}

	mutating func visit(_ node: WhileStmtSyntax, context: Context) -> ValueType? {
		_ = visit(node.condition, context: context)

		context.withScope {
			_ = visit(node.body, context: $0)
		}

		// TODO: Validate condition is bool
		return nil
	}

	mutating func visit(_: BinaryOperatorSyntax, context _: Context) -> ValueType? {
		nil
	}

	mutating func visit(_: ParameterListSyntax, context _: Context) -> ValueType? {
		// TODO: handle type decls
		return nil
	}

	mutating func visit(_ node: ArgumentListSyntax, context: Context) -> ValueType? {
		for argument in node.arguments {
			_ = visit(argument, context: context)
			// TODO: Validate
		}

		return nil
	}

	mutating func visit(_ node: ArrayLiteralSyntax, context: Context) -> ValueType? {
		if node.elements.isEmpty {
			return nil
		}

		let elemDefs = node.elements.arguments.compactMap {
			visit($0, context: context)
		}

		// TODO: Check taht they match or add heterogenous arrays who knows
		let firstElemDef = elemDefs[0]

		define(node, as: .array(firstElemDef))

		return .array(firstElemDef)
	}

	mutating func visit(_ node: IdentifierSyntax, context: Context) -> ValueType? {
		return context.lookup(node)
	}

	mutating func visit(_ node: ReturnStmtSyntax, context: Context) -> ValueType? {
		return visit(node.value, context: context)
	}

	mutating func visit(_ node: ExprStmtSyntax, context: Context) -> ValueType? {
		_ = visit(node.expr, context: context)
		return .void // Statements dont have types... fow now?????
	}

	mutating func visit(_ node: PropertyAccessExpr, context: Context) -> ValueType? {
		guard let receiverDef = visit(node.receiver, context: context) else {
			error(node.receiver, "could not determine type")
			return nil
		}

		if let property = receiverDef.property(named: node.property.lexeme) {
			define(node.property, as: property.type, ref: property.definition)
			context.define(node.property, as: property.type)
			return property.type
		}

		return nil
	}

	mutating func visit(_ node: LiteralExprSyntax, context _: Context) -> ValueType? {
		let type: ValueType = switch node.kind {
		case .nil: .nil
		case .true: .bool
		case .false: .bool
		}

		define(node, as: type)
		return type
	}

	mutating func visit(_ node: UnaryExprSyntax, context: Context) -> ValueType? {
		guard let exprDef = visit(node.rhs, context: context) else {
			error(node.rhs, "could not determine type")
			return nil
		}

		switch node.op.kind {
		case .bang:
			if exprDef != .bool {
				error(node, "can't negate \(exprDef)")
				return nil
			}

			define(node, as: .bool)

			return .bool
		case .minus:
			if exprDef != .int {
				error(node, "can't negate \(exprDef)")
				return nil
			}

			define(node, as: .int)

			return .int
		}
	}

	mutating func visit(_ node: ErrorSyntax, context _: Context) -> ValueType? {
		ValueType(id: -99, name: "Error: \(node.description)", definition: node)
	}

	mutating func visit(_ node: ClassDeclSyntax, context: Context) -> ValueType? {
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
			as: classType
		)

		return classType
	}

	mutating func visit(_ node: BinaryExprSyntax, context: Context) -> ValueType? {
		guard let lhsDef = visit(node.lhs, context: context) else {
			error(node.lhs, "unable to determine type")
			return nil
		}

		guard let rhsDef = visit(node.rhs, context: context) else {
			error(node.rhs, "unable to determine type")
			return nil
		}

		guard lhsDef == rhsDef else {
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
			define(node, as: .bool)
			return .bool
		} else {
			define(node, as: lhsDef)
			return lhsDef
		}
	}

	mutating func visit(_ node: IntLiteralSyntax, context _: Context) -> ValueType? {
		define(node, as: .int)

		return .int
	}

	mutating func visit(_ node: FunctionDeclSyntax, context: Context) -> ValueType? {
		let declDef: ValueType? = if let typeDecl = node.typeDecl, let type = visit(typeDecl, context: context) {
			ValueType.function(type)
		} else {
			nil
		}

		_ = visit(node.body, context: context)

		var lastReturnDef: ValueType?
		let returnDefs: [ValueType] = node.body.decls.compactMap { decl -> ValueType? in
			guard let stmt = decl.as(ReturnStmtSyntax.self) else {
				return nil
			}

			guard let def = visit(stmt, context: context) else {
				if declDef == nil {
					error(stmt.value, "could not determine return type")
				}

				return nil
			}

			if let lastReturnDef, !lastReturnDef.assignable(from: def) {
				error(stmt.value, "Function cannot return different types")
				return nil
			}

			if let declDef, !declDef.returns!.value.assignable(from: def) {
				error(stmt.value, "Not assignable to \(declDef.returns!.value)")
				return nil
			}

			lastReturnDef = def

			return def
		}

		let returnDef = returnDefs.first

		let typedef = ValueType.function(returnDef ?? .void)
		let def = declDef ?? typedef

		define(node, as: def)

		if context.currentClass != nil {
			// This only throws when there's no class
			try! context.define(member: node.name.lexeme, as: def, at: node)
		} else {
			context.define(node.name, as: def)
		}

		return def
	}

	mutating func visit(_ node: VariableExprSyntax, context: Context) -> ValueType? {
		context.lookup(node)
	}

	mutating func visit(_ node: StringLiteralSyntax, context _: Context) -> ValueType? {
		define(node, as: .string)
		return .string
	}
}
