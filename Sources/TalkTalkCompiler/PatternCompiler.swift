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

	func compileCase() throws {
		try target.accept(compiler, chunk)
		try caseStatement.patternAnalyzed.accept(compiler, chunk)

		chunk.emit(.opcode(.match), line: caseStatement.location.line)
	}

	func compileBody() throws {
		let casePattern = try compilerPattern(from: caseStatement.patternAnalyzed)

		if case let .call(_, caseArgs) = casePattern {
			for (i, arg) in caseArgs.enumerated() {
				defineLocals(for: arg, index: i)
			}
		}

		for stmt in caseStatement.bodyAnalyzed {
			try stmt.accept(compiler, chunk)
		}
	}

	func defineLocals(for arg: any AnalyzedSyntax, index: Int) {
		switch arg {
		case let arg as any AnalyzedVarLetDecl:
			let variable = compiler.defineLocal(name: arg.name, compiler: compiler, chunk: chunk)

			chunk.emit(.opcode(.binding), line: arg.location.line)
			chunk.emit(.byte(Byte(index)), line: arg.location.line)

			// TODO: Make sure these values don't leak
			chunk.emit(.opcode(.setLocal), line: arg.location.line)
			chunk.emit(variable.code, line: arg.location.line)
		case let arg as AnalyzedCallExpr:
			for (i, subarg) in arg.argsAnalyzed.enumerated() {
				defineLocals(for: subarg.expr, index: index)
			}
		default:
			print(arg)
			()
		}
	}
}
