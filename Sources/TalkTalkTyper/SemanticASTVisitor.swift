//
//  SemanticASTVisitor.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax

public struct SemanticError {
	public var location: any Syntax
	public var message: String
}

// The semantic ast visitor is responsible for converting the AST to a new
// tree that contains info about types and closures and scopes and whatnot
public struct SemanticASTVisitor: ASTVisitor {
	public let rootScope = Scope()
	let ast: any Syntax

	public init(ast: some Syntax) {
		self.ast = ast
	}

	public func visit() -> any SemanticNode {
		ast.accept(self, context: rootScope)
	}

	func error(_ syntax: any Syntax, _ message: String) {
		rootScope.errors.append(.init(location: syntax, message: message))
	}

	// MARK: Visits

	public func visit(_ node: TypeDeclSyntax, context: Scope) -> any SemanticNode {
		let type: any SemanticType = switch node.name.lexeme {
		case "Int": .int
		case "String": .string
		case "Bool": .bool
		case "Void": .void
		default: .unknown
		}

		return TypeDeclaration(syntax: node, type: type, scope: context)
	}

	public func visit(_ node: ErrorSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: ParameterListSyntax, context: Scope) -> any SemanticNode {
		for parameter in node.parameters {
			// Define the parameters into the scope of the function body. We don't know
			// the types yet so they're unknown (TODO: type decls for fn params)
			context.bind(
				name: parameter.lexeme,
				to: .unknown(syntax: parameter, scope: context),
				traits: [.initialized, .constant]
			)
		}

		return .void(syntax: node, scope: context)
	}

	public func visit(_ node: ArgumentListSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: BinaryOperatorSyntax, context: Scope) -> any SemanticNode {
		let operandTypes: [any SemanticType] = switch node.kind {
		case .andAnd, .pipePipe:
			[.bool]
		default:
			[.int]
		}

		return OperatorNode(
			syntax: node,
			scope: context,
			allowedOperandTypes: operandTypes
		)
	}

	public func visit(_ node: UnaryOperator, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: IfExprSyntax, context scope: Scope) -> any SemanticNode {
		let condition = visit(node.condition, context: scope)

		if condition.type.description != "Bool" {
			error(node.condition, "must be Bool")
		}

		let consesquence = visit(node.thenBlock, context: scope)
		let alternative = visit(node.elseBlock, context: scope)

		if !consesquence.type.assignable(from: alternative.type) {
			error(node, "Both branches of an if expression must match")
		}

		// TODO: Check consequence and alternative agree, condition is bool
		return IfExpression(
			syntax: node,
			scope: scope,
			type: consesquence.type,
			condition: condition,
			consequence: consesquence,
			alternative: alternative
		)
	}

	public func visit(_ node: ArrayLiteralSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: PropertyAccessExpr, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: LiteralExprSyntax, context: Scope) -> any SemanticNode {
		switch node.kind {
		case .true:
			Literal(syntax: node, scope: context, type: .bool)
		case .false:
			Literal(syntax: node, scope: context, type: .bool)
		case .nil:
			// TODO: hmm
			Literal(syntax: node, scope: context, type: .bool)
		}
	}

	public func visit(_ node: AssignmentExpr, context: Scope) -> any SemanticNode {
		let lhs = visit(node.lhs, context: context)
		let rhs = visit(node.rhs, context: context)

		guard let binding = context.binding(for: lhs) else {
			error(node.lhs, "Unknown variable")
			return .unknown(syntax: node, scope: context)
		}

		if binding.isConstant, binding.isInitialized {
			error(node.lhs, "Cannot reassign constant")
		} else if !binding.isInitialized {
			binding.node.type = lhs.type
			binding.traits.insert(.initialized)
			context.bind(
				name: binding.name,
				to: rhs,
				traits: binding.traits
			)
		}

		if lhs.type.assignable(from: rhs.type) {
			return lhs
		}

		error(node, "Cannot assign \(rhs) to \(lhs.type)")
		return .unknown(syntax: node, scope: context)
	}

	public func visit(_ node: VariableExprSyntax, context scope: Scope) -> any SemanticNode {
		if let binding = scope.locals[node.name.lexeme] {
			return binding.node
		}

		error(node, "Undefined variable: \(node.name)")
		return .unknown(syntax: node, scope: scope)
	}

	public func visit(_ node: StringLiteralSyntax, context: Scope) -> any SemanticNode {
		Literal(syntax: node, scope: context, type: .string)
	}

	public func visit(_ node: IntLiteralSyntax, context: Scope) -> any SemanticNode {
		Literal(syntax: node, scope: context, type: .int)
	}

	public func visit(_ node: IdentifierSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: BinaryExprSyntax, context scope: Scope) -> any SemanticNode {
		let rawLHS = visit(node.lhs, context: scope)
		let rawRHS = visit(node.rhs, context: scope)
		let op = visit(node.op, context: scope) as! OperatorNode

		let (lhs, rhs) = inferTypes(
			for: (rawLHS, rawRHS),
			in: scope,
			allowed: op.allowedOperandTypes
		)

		if !checkTypeAgreement(of: lhs, rhs) {
			error(node, "Binary expression types must match")
		}

		return BinaryOpExpression(
			scope: scope,
			syntax: node,
			type: lhs.type,
			lhs: lhs as! Expression,
			rhs: rhs as! Expression,
			op: op
		)
	}

	public func visit(_ node: UnaryExprSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: CallExprSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: GroupExpr, context: Scope) -> any SemanticNode {
		visit(node.expr, context: context)
	}

	public func visit(_ node: ReturnStmtSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: WhileStmtSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: StmtSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: IfStmtSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: BlockStmtSyntax, context scope: Scope) -> any SemanticNode {
		// Currently just use the last return value as the implicit return of the block.
		// Eventually it might be nice to require a `return` if there is more than one
		// decl in the block.
		var lastReturn: (any SemanticNode)?

		for decl in node.decls {
			lastReturn = visit(decl, context: scope)
		}

		if var lastReturn, lastReturn.type.description == "Unknown",
		   let expectedReturnVia = scope.expectedReturnVia
		{
			scope.inferType(for: &lastReturn, from: expectedReturnVia)
			return lastReturn
		}

		return lastReturn ?? .void(syntax: node, scope: scope)
	}

	public func visit(_ node: ExprStmtSyntax, context: Scope) -> any SemanticNode {
		visit(node.expr, context: context)
	}

	public func visit(_ node: PropertyDeclSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: InitDeclSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: ClassDeclSyntax, context: Scope) -> any SemanticNode {
		.placeholder(node, context)
	}

	public func visit(_ node: LetDeclSyntax, context binding: Scope) -> any SemanticNode {
		handleVarLet(node, binding: binding)
	}

	public func visit(_ node: VarDeclSyntax, context binding: Scope) -> any SemanticNode {
		handleVarLet(node, binding: binding)
	}

	public func visit(_ node: FunctionDeclSyntax, context: Scope) -> any SemanticNode {
		// Introduce a new scope
		let innerBinding = context.child()

		// Call into handle function, which could potentially do multiple passes
		let function = handleFunction(node, scope: innerBinding)

		// Bind the function by name to the enclosing scope
		context.bind(
			name: node.name.lexeme,
			to: function,
			traits: [.constant, .initialized]
		)

		return function
	}

	public func visit(_ node: ProgramSyntax, context scope: Scope) -> any SemanticNode {
		let declarations = node.decls.map {
			visit($0, context: scope)
		}

		return Program(syntax: node, scope: scope, declarations: declarations)
	}

	// MARK: Helpers

	func handleFunction(_ node: FunctionDeclSyntax, scope: Scope) -> any SemanticNode {
		let typeDeclNode = handleTypeDecl(binding: scope) { node.typeDecl }

		if let type = typeDeclNode?.type {
			scope.expectedReturnVia = typeDeclNode
		}

		// Make sure the parameters are declared inside the function body
		_ = visit(node.parameters, context: scope)

		// Visit the function body, if we don't have a type decl, maybe we can figure out
		// what the return type is from here
		let body = visit(node.body, context: scope)

		// If we have a type decl, check that the function actually returns it
		if let typeDeclNode, !typeDeclNode.type.assignable(from: body.type) {
			error(node, "Cannot return \(body.type) from \(node.name), expected \(typeDeclNode.type)")
		}

		let functionType = FunctionType(
			name: node.name.lexeme,
			returns: body.type
		)

		return Function(syntax: node, scope: scope, prototype: functionType)
	}

	func handleTypeDecl(binding: Scope, _ block: () -> TypeDeclSyntax?) -> (any SemanticNode)? {
		if let typeDecl = block() {
			return visit(typeDecl, context: binding)
		} else {
			return nil
		}
	}

	func handleVarLet(_ node: any VarLetDecl, binding: Scope) -> any SemanticNode {
		let name = node.variable.lexeme

		let typeDeclNode = handleTypeDecl(binding: binding) { node.typeDecl }

		var type: any SemanticType = UnknownType()
		var traits: Set<Binding.Trait> = []

		if let expr = node.expr,
		   let exprNode = visit(expr, context: binding) as? any Expression
		{
			// Check to see if there's a type decl. If it doesn't agree with
			// the expr node, we're in trouble
			if let typeDeclNode, !typeDeclNode.type.assignable(from: exprNode.type) {
				error(node, "Cannot assign \(exprNode.type) to \(typeDeclNode.type)")
			}

			traits.insert(.initialized)

			if node is LetDeclSyntax {
				traits.insert(.constant)
			}

			type = exprNode.type
			binding.bind(
				name: name,
				to: exprNode,
				traits: traits
			)

			return VarLetDeclaration(
				type: type,
				syntax: node,
				scope: binding,
				expression: exprNode
			)
		} else {
			if node is LetDeclSyntax {
				traits.insert(.constant)
			}

			binding.bind(
				name: name,
				to: typeDeclNode ?? .unknown(syntax: node, scope: binding),
				traits: traits
			)

			return VarLetDeclaration(
				type: type,
				syntax: node,
				scope: binding
			)
		}
	}

	// TODO: maybe use variadic generics here?
	func inferTypes(
		for tuple: (any SemanticNode, any SemanticNode),
		in scope: Scope,
		allowed: [any SemanticType]
	) -> (any SemanticNode, any SemanticNode) {
		var known: (any SemanticNode)?
		var nodes = [tuple.0, tuple.1]

		// Do a couple passes
		for _ in 0..<2 {
			for (i, node) in nodes.enumerated() {
				// Set the first known type
				if known == nil, node.type.isKnown {
					known = node
				}

				if let known, !allowed.contains(where: { $0.description == known.type.description }) {
					error(node.syntax, "type not allowed, allowed types: \(allowed.map(\.description))")
				}

				if !node.type.isKnown, let known {
					var node = node
					scope.inferType(for: &node, from: known)
					nodes[i] = node
				}
			}
		}

		return (nodes[0], nodes[1])
	}

	func checkTypeAgreement(of nodes: (any SemanticNode)...) -> Bool {
		let known = nodes[0].type

		for i in 1..<nodes.count {
			if !known.assignable(from: nodes[i].type) {
				return false
			}
		}

		return true
	}
}
