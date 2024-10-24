//
//  CaseStmtCompiler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/10/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode
import TypeChecker

enum CompilerPattern {
	// If we're matching something that looks like a call expr
	case call(any AnalyzedSyntax, [any AnalyzedSyntax])

	// If we're matching something that looks like a value expr
	case value(any AnalyzedExpr)
}

struct CaseStmtCompiler {
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
		if let pattern = caseStatement.patternAnalyzed {
			try target.accept(compiler, chunk)
			try pattern.accept(compiler, chunk)
		} else {
			// If it's the default case, just emit two trues which will match.
			chunk.emit(.opcode(.true), line: caseStatement.location.line)
			chunk.emit(.opcode(.true), line: caseStatement.location.line)
		}

		chunk.emit(.opcode(.match), line: caseStatement.location.line)
	}

	func compileBody() throws {
		if let pattern = caseStatement.patternAnalyzed {
			let casePattern = try compilerPattern(from: pattern)

			if case let .call(_, caseArgs) = casePattern {
				for (i, arg) in caseArgs.enumerated() {
					defineLocals(for: arg, index: i)
				}
			}
		}

		for stmt in caseStatement.bodyAnalyzed {
			try stmt.accept(compiler, chunk)
		}

//		chunk.emit(opcode: .returnVoid, line: UInt32(caseStatement.location.end.line))
	}

	func defineLocals(for arg: any AnalyzedSyntax, index: Int) {
		switch arg {
		case let arg as any AnalyzedVarLetDecl:
			let variable = compiler.defineLocal(name: arg.name, compiler: compiler, chunk: chunk)

			chunk.emit(.opcode(.binding), line: arg.location.line)
			chunk.emit(.symbol(.value(compiler.module.name, arg.name)), line: arg.location.line)

			chunk.emit(.opcode(.setLocal), line: arg.location.line)
			chunk.emit(variable.code, line: arg.location.line)
		case let arg as AnalyzedCallExpr:
			for (i, subarg) in arg.argsAnalyzed.enumerated() {
				defineLocals(for: subarg.expr, index: i + index + 1)
			}
		default:
			()
		}
	}
}
