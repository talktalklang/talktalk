//
//  Completer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/26/24.
//

public struct Completer: AnalyzedVisitor {
	var exprs: [any AnalyzedExpr]

	public init(exprs: [any AnalyzedExpr]) {
		self.exprs = exprs
	}

	public func completions(at: [Int]) throws -> [String] {
		let result = Context()
		for expr in exprs {
			try expr.accept(self, result)
		}
		return result.results
	}

	// MARK: Visitor stuff
	public typealias Value = Void
	public class Context {
		var results: [String] = []
	}

	public func visit(_ expr: AnalyzedCallExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedDefExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedErrorSyntax, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedLiteralExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedVarExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedBinaryExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedUnaryExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedIfExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedFuncExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedBlockExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedWhileExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedParamsExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedReturnExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedMemberExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedDeclBlock, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedStructExpr, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedVarDecl, _ context: Context) throws -> Value {}

	public func visit(_ expr: AnalyzedLetDecl, _ context: Context) throws -> Value {}

}
