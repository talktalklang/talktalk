//
//  AstResolver+StmtVisitor.swift
//
//
//  Created by Pat Nakajima on 6/29/24.
//

extension AstResolver: StmtVisitor {
	mutating func visit(_ stmt: PrintStmt) throws {
		try resolve(stmt.expr)
	}

	mutating func visit(_ stmt: ExpressionStmt) throws {
		try resolve(stmt.expr)
	}

	mutating func visit(_ stmt: VarStmt) throws {
		declare(stmt.name)

		if let initializer = stmt.initializer {
			try resolve(initializer)
		}

		define(stmt.name)
	}

	mutating func visit(_ stmt: BlockStmt) throws {
		beginScope()
		try resolve(stmt.statements)
		endScope()
	}

	mutating func visit(_ stmt: IfStmt) throws {
		try resolve(stmt.condition)
		try resolve(stmt.thenStatement)

		if let elseStatement = stmt.elseStatement {
			try resolve(elseStatement)
		}
	}

	mutating func visit(_ stmt: WhileStmt) throws {
		try resolve(stmt.condition)
		try resolve(stmt.body)
	}

	mutating func visit(_ stmt: FunctionStmt) throws {
		declare(stmt.name)
		define(stmt.name)

		try resolveFunction(stmt, .function)
	}

	mutating func visit(_ stmt: ReturnStmt) throws {
		if currentFunction == .none {
			TalkTalk.error("Can't return from top level code.", token: stmt.token)
			throw ResolverError.topLevelReturn
		}

		if let value = stmt.value {
			try resolve(value)
		}
	}

	mutating func visit(_ stmt: ClassStmt) throws {
		declare(stmt.name)
		define(stmt.name)

		beginScope()
		define("self")

		for method in stmt.methods {
			try resolveFunction(method, .method)
		}

		for initializer in stmt.inits {
			try resolveFunction(initializer, .initializer)
		}

		endScope()
	}
}
