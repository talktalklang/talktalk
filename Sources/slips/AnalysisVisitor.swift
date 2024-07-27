//
//  AnalysisVisitor.swift
//  Slips
//
//  Created by Pat Nakajima on 7/27/24.
//

public protocol AnalyzedVisitor {
	associatedtype Context
	associatedtype Value

	func visit(_ expr: AnalyzedCallExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedDefExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedErrorExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedLiteralExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedVarExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedAddExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedIfExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedFuncExpr, _ context: Context) -> Value
	func visit(_ expr: AnalyzedParamsExpr, _ context: Context) -> Value
}
