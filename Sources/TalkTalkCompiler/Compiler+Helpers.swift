//
//  Compiler+Helpers.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import Foundation
import LLVM
import TalkTalkAnalysis

extension Compiler {
	func allocateLocals(funcExpr: AnalyzedFuncExpr, context: Context) {
		log("-> allocating locals for \(funcExpr.name ?? funcExpr.autoname)")

		// Figure out which of this function's values are captured by children and malloc some heap space
		// for them.
		for binding in funcExpr.environment.bindings {
			// We already have this (probably a capture so just go on to the next one
			if context.environment.has(binding.name) {
				log("  -> environment already contains \(binding.name), skipping")
				continue
			}

			if binding.isCaptured {
				let storage = builder.malloca(type: irType(for: binding.type), name: binding.name)
				log(
					"  -> emitting captured binding in \(funcExpr.name ?? "<unnamed func>"): \(binding.name) \(binding.expr.description) (\(storage.ref))"
				)
				context.environment.declare(binding.name, as: storage)
			} else if case let .struct(structType) = binding.type {
				log("  -> emitting type binding and method table for \(structType.name!)")

				let structTypeLLVM = structType.toLLVM(in: builder)
				let globalType = builder.defineGlobal(structType: structTypeLLVM, name: structType.name!)
				context.environment.defineType(structTypeLLVM, pointer: globalType)
			} else if case .function(_, _, _, _) = binding.type {
				let type = binding.type.irType(in: builder) as! LLVM.ClosureType
				context.environment.defineFunction(binding.name, type: type, ref: builder.mainRef)
			} else if !binding.isParameter {
				let storage = builder.alloca(type: irType(for: binding.type), name: binding.name)
				log(
					"  -> emitting stack binding in \(funcExpr.name ?? "<unnamed func>"): \(binding.name) \(binding.expr.description) (\(storage.ref))"
				)
				context.environment.declare(binding.name, as: storage)
			}
		}
	}

	func captureClosure(_ funcExpr: AnalyzedFuncExpr, _ context: Context) -> LLVM.Closure {
		// Create a closure for this function, moving locals to the heap. For values already on the heap,
		// just reuse the values.
		var captures: [(name: String, pointer: any LLVM.StoredPointer)] = []
		for (_, capture) in funcExpr.environment.captures.enumerated() {
			if capture.name == "self" { continue }

			log("-> capturing \(capture.name) in \(funcExpr)")
			captures.append((capture.name, context.environment.capture(capture.name, with: builder)))
		}

		let closureType = funcExpr.type.irType(in: builder) as! LLVM.ClosureType
		for (i, capture) in captures.enumerated() {
			context.environment.bindings[capture.0] = .capture(i, closureType)
		}

		return LLVM.Closure(type: closureType, functionType: closureType.functionType, captures: captures)
	}

//	func createEnvironmentStruct(
//		type: LLVM.ClosureType,
//		from captures: [(String, any LLVM.StoredPointer)]
//	) -> LLVM.Closure {
//		var offsets: [String: Int] = [:]
//		var capturePointers: [any LLVM.StoredPointer] = []
//		for (i, capture) in captures.enumerated() {
//			offsets[capture.0] = i
//			capturePointers.append(capture.1)
//		}
//
//		let pointer = builder.capturesStruct(type: type, values: captures)
//		let value = LLVM.CapturesStruct(
//			type: type,
//			offsets: offsets,
//			captures: capturePointers,
//			ref: pointer.ref
//		)
//
//		return value
//	}

	func main(_ funcExpr: AnalyzedFuncExpr, _ context: Context) throws -> any LLVM.EmittedValue {
		var functionType = irType(for: funcExpr).as(LLVM.ClosureType.self).functionType
		functionType.name = funcExpr.name ?? funcExpr.autoname

		let main = builder.main(functionType: functionType, builtins: Builtins.list)

		allocateLocals(funcExpr: funcExpr, context: context)
		_ = captureClosure(funcExpr, context)

		var lastReturn: (any LLVM.EmittedValue)?
		for expr in funcExpr.bodyAnalyzed.exprsAnalyzed {
			lastReturn = try expr.accept(self, context)
		}

		if let lastReturn, let type = lastReturn.type as? LLVM.IntType {
			if type.width == 32 {
				_ = builder.emit(return: lastReturn)
			} else {
				let ret = LLVM.IntType.i32.constant(0)
				let emit = LLVM.EmittedIntValue(type: .i32, ref: ret.valueRef(in: builder))
				_ = builder.emit(return: emit)
			}

		} else {
			_ = builder.emit(constant: LLVM.IntType.i32.constant(1))
		}

		return main
	}

	func irType(for type: ValueType) -> any LLVM.IRType {
		return type.irType(in: builder)
	}

	func irType(for expr: AnalyzedExpr) -> any LLVM.IRType {
		expr.type.irType(in: builder)
	}

	func log(_ string: String) {
		if verbose {
			FileHandle.standardError.write(Data((string + "\n").utf8))
		}
	}
}
