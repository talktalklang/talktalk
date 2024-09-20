//
//  PatternCompiler.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/20/24.
//

import TalkTalkAnalysis
import TalkTalkBytecode

struct PatternCompiler {
	let syntax: any AnalyzedSyntax
	let allowsImplicitDeclaration: Bool
	let chunk: Chunk
	let compiler: ChunkCompiler

	func compile() throws {
		switch syntax {
		case let syntax as AnalyzedVarExpr:
			try compileVarExpr(syntax: syntax)
		case let syntax as any AnalyzedVarLetDecl:
			try compileVarLet(syntax: syntax)
		default:
			throw CompilerError.invalidPattern("unable to compile pattern: \(syntax)")
		}
	}

	func compileVarExpr(syntax: AnalyzedVarExpr) throws {
		if allowsImplicitDeclaration {
			let variable = compiler.defineLocal(name: syntax.name, compiler: compiler, chunk: chunk)
			chunk.emit(opcode: .setLocal, line: syntax.location.line)
			chunk.emit(.symbol(.value(compiler.module.name, variable.name)), line: syntax.location.line)
		}
	}

	func compileVarLet(syntax: any AnalyzedVarLetDecl) throws {
		
	}
}
