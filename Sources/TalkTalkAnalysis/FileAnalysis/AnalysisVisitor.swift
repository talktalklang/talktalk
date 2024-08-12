//
//  AnalysisVisitor.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/27/24.
//

public protocol AnalyzedVisitor {
	associatedtype Context
	associatedtype Value

	func visit(_ expr: AnalyzedCallExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedDefExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedErrorSyntax, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedLiteralExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedVarExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedBinaryExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedUnaryExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedIfExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedFuncExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedBlockExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedWhileExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedParamsExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedReturnExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedIdentifierExpr, _ context: Context) throws -> Value

	func visit(_ expr: AnalyzedMemberExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedDeclBlock, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedStructExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedVarDecl, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedLetDecl, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedImportStmt, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedInitDecl, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedGenericParams, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedTypeExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedExprStmt, _ context: Context) throws -> Value
}
