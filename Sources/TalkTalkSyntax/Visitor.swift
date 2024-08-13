//
//  Visitor.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol Visitor {
	associatedtype Context
	associatedtype Value

	func visit(_ expr: CallExpr, _ context: Context) throws -> Value
	func visit(_ expr: DefExpr, _ context: Context) throws -> Value
	func visit(_ expr: IdentifierExpr, _ context: Context) throws -> Value
	func visit(_ expr: LiteralExpr, _ context: Context) throws -> Value
	func visit(_ expr: VarExpr, _ context: Context) throws -> Value
	func visit(_ expr: UnaryExpr, _ context: Context) throws -> Value
	func visit(_ expr: BinaryExpr, _ context: Context) throws -> Value
	func visit(_ expr: IfExpr, _ context: Context) throws -> Value
	func visit(_ expr: WhileExpr, _ context: Context) throws -> Value
	func visit(_ expr: BlockExpr, _ context: Context) throws -> Value
	func visit(_ expr: FuncExpr, _ context: Context) throws -> Value
	func visit(_ expr: ParamsExpr, _ context: Context) throws -> Value
	func visit(_ expr: Param, _ context: Context) throws -> Value
	func visit(_ expr: GenericParams, _ context: Context) throws -> Value

	func visit(_ expr: StructExpr, _ context: Context) throws -> Value
	func visit(_ expr: DeclBlockExpr, _ context: Context) throws -> Value
	func visit(_ expr: VarDecl, _ context: Context) throws -> Value
	func visit(_ expr: ErrorSyntax, _ context: Context) throws -> Value
	func visit(_ expr: MemberExpr, _ context: Context) throws -> Value
	func visit(_ expr: ReturnExpr, _ context: Context) throws -> Value
	func visit(_ expr: InitDecl, _ context: Context) throws -> Value
	func visit(_ expr: ImportStmt, _ context: Context) throws -> Value
	func visit(_ expr: TypeExpr, _ context: Context) throws -> Value
	func visit(_ expr: ExprStmt, _ context: Context) throws -> Value
	func visit(_ expr: IfStmt, _ context: Context) throws -> Value

	func visit(_ expr: StructDecl, _ context: Context) throws -> Value

	// GENERATOR_INSERTION
}
