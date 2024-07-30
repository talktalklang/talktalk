//
//  AnalysisVisitor.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/27/24.
//

public protocol AnalyzedVisitor {
	associatedtype Context
	associatedtype Value

	func visit(_ expr: AnalyzedCallExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedDefExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedErrorSyntax, _ context: Context) -> Value
	func visit(_ expr: AnalyzedLiteralExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedVarExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedBinaryExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedIfExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedFuncExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedBlockExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedWhileExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedParamsExpr, _ context: Context) -> Value

	func visit(_ expr: AnalyzedMemberExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedDeclBlock, _ context: Context) -> Value
	func visit(_ expr: AnalyzedStructExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedVarDecl, _ context: Context) -> Value
	func visit(_ expr: AnalyzedLetDecl, _ context: Context) -> Value
}
