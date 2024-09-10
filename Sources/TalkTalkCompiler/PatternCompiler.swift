//
//  PatternCompiler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/10/24.
//

import TypeChecker
import TalkTalkAnalysis
import TalkTalkBytecode

enum CompilerPattern {
	// If we're matching something that looks like a call expr
	case call(any AnalyzedSyntax, [any AnalyzedSyntax])

	// If we're matching something that looks like a value expr
	case value(any AnalyzedExpr)
}

struct PatternCompiler {
	let target: any AnalyzedExpr
	let caseStatement: AnalyzedCaseStmt
	let compiler: ChunkCompiler
	let chunk: Chunk

	init(target: any AnalyzedExpr, caseStatement: AnalyzedCaseStmt, compiler: ChunkCompiler, chunk: Chunk) {
		self.target = target
		self.caseStatement = caseStatement
		self.compiler = compiler
		self.chunk = chunk
	}

	func compilerPattern(from syntax: any AnalyzedSyntax) throws -> CompilerPattern {
		switch syntax {
		case let syntax as AnalyzedCallExpr:
			return .call(syntax.calleeAnalyzed, syntax.argsAnalyzed.map(\.expr))
		case let syntax as any AnalyzedExpr:
			return .value(syntax)
		default:
			throw CompilerError.invalidPattern("Could not figure out pattern for: \(syntax.description)")
		}
	}

	func compileBody(from syntax: any AnalyzedExpr) throws {
		
	}

	func compileCase() throws {
		let targetPattern = try compilerPattern(from: target)
		let casePattern = try compilerPattern(from: caseStatement.patternAnalyzed)

		switch (targetPattern, casePattern) {
		case let (.call(targetType, targetArgs), .call(caseType, caseArgs)):
			try targetType.accept(compiler, chunk)
			try caseType.accept(compiler, chunk)

			chunk.emit(.opcode(.equal), line: caseStatement.location.line)

			for (i, arg) in caseArgs.enumerated() where arg.inferenceType != .void {
				try targetArgs[i].accept(compiler, chunk)
				try arg.accept(compiler, chunk)
				chunk.emit(.opcode(.equal), line: arg.location.line)
				chunk.emit(.opcode(.and), line: arg.location.line)
			}
		default:
			try target.accept(compiler, chunk)
			try caseStatement.patternAnalyzed.accept(compiler, chunk)

			chunk.emit(.opcode(.equal), line: caseStatement.location.line)
		}
	}

	func compileBody() throws {
		let targetPattern = try compilerPattern(from: target)
		let casePattern = try compilerPattern(from: caseStatement.patternAnalyzed)

		if case let (.call(targetType, targetArgs), .call(caseType, caseArgs)) = (targetPattern, casePattern) {
			for (i, arg) in caseArgs.enumerated() where arg is any AnalyzedVarLetDecl {
				// swiftlint:disable force_cast
				let arg = arg as! any AnalyzedVarLetDecl
				// swiftlint:enable force_cast

				let variable = compiler.defineLocal(name: arg.name, compiler: compiler, chunk: chunk)
				try targetArgs[i].accept(compiler, chunk)

				// TODO: Make sure these values don't leak
				chunk.emit(.opcode(.setLocal), line: arg.location.line)
				chunk.emit(variable.code, line: arg.location.line)
			}
		}

		for stmt in caseStatement.bodyAnalyzed {
			try stmt.accept(compiler, chunk)
		}
	}
}
