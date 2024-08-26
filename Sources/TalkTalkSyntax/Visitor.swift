//
//  Visitor.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

public protocol Visitor {
	associatedtype Context
	associatedtype Value

	func visit(_ expr: CallExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: DefExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: IdentifierExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: LiteralExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: VarExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: UnaryExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: BinaryExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: IfExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: WhileStmtSyntax, _ context: Context) throws -> Value
	func visit(_ expr: BlockStmtSyntax, _ context: Context) throws -> Value
	func visit(_ expr: FuncExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: ParamsExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: ParamSyntax, _ context: Context) throws -> Value
	func visit(_ expr: GenericParamsSyntax, _ context: Context) throws -> Value
	func visit(_ expr: CallArgument, _ context: Context) throws -> Value
	func visit(_ expr: StructExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: DeclBlockSyntax, _ context: Context) throws -> Value
	func visit(_ expr: VarDeclSyntax, _ context: Context) throws -> Value
	func visit(_ expr: LetDeclSyntax, _ context: Context) throws -> Value
	func visit(_ expr: ParseErrorSyntax, _ context: Context) throws -> Value
	func visit(_ expr: MemberExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: ReturnStmtSyntax, _ context: Context) throws -> Value
	func visit(_ expr: InitDeclSyntax, _ context: Context) throws -> Value
	func visit(_ expr: ImportStmtSyntax, _ context: Context) throws -> Value
	func visit(_ expr: TypeExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: ExprStmtSyntax, _ context: Context) throws -> Value
	func visit(_ expr: IfStmtSyntax, _ context: Context) throws -> Value
	func visit(_ expr: StructDeclSyntax, _ context: Context) throws -> Value
	func visit(_ expr: ArrayLiteralExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: SubscriptExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: DictionaryLiteralExprSyntax, _ context: Context) throws -> Value
	func visit(_ expr: DictionaryElementExprSyntax, _ context: Context) throws -> Value
	// GENERATOR_INSERTION
}
