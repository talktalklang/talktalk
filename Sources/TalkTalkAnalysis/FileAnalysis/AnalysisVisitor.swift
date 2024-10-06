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
	func visit(_ expr: AnalyzedBlockStmt, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedWhileStmt, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedParamsExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedParam, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedReturnStmt, _ context: Context) throws -> Value
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
	func visit(_ expr: AnalyzedIfStmt, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedStructDecl, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedArrayLiteralExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedSubscriptExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedDictionaryLiteralExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedDictionaryElementExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedProtocolDecl, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedProtocolBodyDecl, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedFuncSignatureDecl, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedEnumDecl, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedEnumCaseDecl, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedMatchStatement, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedCaseStmt, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedEnumMemberExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedInterpolatedStringExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedForStmt, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedLogicalExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedGroupedExpr, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedLetPattern, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedPropertyDecl, _ context: Context) throws -> Value
	func visit(_ expr: AnalyzedMethodDecl, _ context: Context) throws -> Value
	// GENERATOR_INSERTION
}
