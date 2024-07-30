//
//  Compiler+Helpers.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import Foundation
import TalkTalkAnalysis
import LLVM

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
					"  -> emitting binding in \(funcExpr): \(binding.name) \(binding.expr.description) (\(storage.ref))"
				)
				context.environment.declare(binding.name, as: storage)
			} else {
				let storage = builder.alloca(type: irType(for: binding.type), name: binding.name)
				log(
					"  -> emitting binding in \(funcExpr): \(binding.name) \(binding.expr.description) (\(storage.ref))"
				)
				context.environment.declare(binding.name, as: storage)
			}
		}
	}

	func emitEnvironment(_ funcExpr: AnalyzedFuncExpr, _ context: Context) -> LLVM.CapturesStruct? {
		if funcExpr.environment.captures.isEmpty {
			return nil
		}

		// Create a closure for this function, moving locals to the heap. For values already on the heap,
		// just reuse the values.
		var captures: [(String, any LLVM.StoredPointer)] = []
		for (_, capture) in funcExpr.environment.captures.enumerated() {
			log("-> capturing \(capture.name) in \(funcExpr)")
			captures.append((capture.name, context.environment.capture(capture.name, with: builder)))
		}

		// Now that we have the captures list built, we can create the StructType for it. We need this in order
		// to be able to GEP into it when we're trying to look up values from the environment during variable
		// resolution (see VarExpr visitor)
		let type = LLVM.StructType(
			name: "Capture(\(captures.map(\.0).joined()))", types: captures.map { $0.1.type })
		for (i, capture) in captures.enumerated() {
			context.environment.bindings[capture.0] = .capture(i, type)
		}

		return createEnvironmentStruct(type: type, from: captures)
	}

	func createEnvironmentStruct(
		type: LLVM.StructType, from captures: [(String, any LLVM.StoredPointer)]
	) -> LLVM.CapturesStruct {
		var offsets: [String: Int] = [:]
		var capturePointers: [any LLVM.StoredPointer] = []
		for (i, capture) in captures.enumerated() {
			offsets[capture.0] = i
			capturePointers.append(capture.1)
		}

		let pointer = builder.struct(type: type, values: captures)
		let value = LLVM.CapturesStruct(
			type: type, offsets: offsets, captures: capturePointers, ref: pointer.ref)

		return value
	}

	func main(_ funcExpr: AnalyzedFuncExpr, _ context: Context) -> any LLVM.EmittedValue {
		var functionType = irType(for: funcExpr).as(LLVM.FunctionType.self)
		functionType.name = funcExpr.name ?? funcExpr.autoname

		let main = builder.main(functionType: functionType, builtins: Builtins.list)

		allocateLocals(funcExpr: funcExpr, context: context)
		_ = emitEnvironment(funcExpr, context)

		var lastReturn: (any LLVM.EmittedValue)?
		for expr in funcExpr.bodyAnalyzed.exprsAnalyzed {
			lastReturn = expr.accept(self, context)
		}

		if let lastReturn {
			_ = builder.emit(return: lastReturn)
		} else {
			_ = builder.emit(constant: LLVM.IntType.i32.constant(1))
		}

		return main
	}

	func irType(for type: ValueType) -> any LLVM.IRType {
		switch type {
		case .int:
			LLVM.IntType.i32
		case let .function(name, returns, params, captures):
			LLVM.FunctionType(
				name: name,
				returnType: irType(for: returns),
				parameterTypes: params.paramsAnalyzed.map { irType(for: $0.type) },
				isVarArg: params.isVarArg,
				captures: LLVM.StructType(
					name: "\(name)Env", types: captures.map { irType(for: $0.binding.type) })
			)
		case .none:
			LLVM.VoidType()
		default:
			fatalError()
		}
	}

	func irType(for expr: AnalyzedExpr) -> any LLVM.IRType {
		switch expr {
		case _ where expr.type == .int:
			return LLVM.IntType.i32
		case let expr as AnalyzedCallExpr:
			let callee = expr.calleeAnalyzed

			guard case let .function(_, returns, _, _) = callee.type else {
				fatalError("\(callee.description) not callable")
			}

			return irType(for: returns)
		case let expr as AnalyzedFuncExpr:
			let returnType =
				if let returns = expr.returnsAnalyzed {
					irType(for: returns)
				} else {
					LLVM.VoidType()
				}

			var functionType = LLVM.FunctionType(
				name: expr.name ?? expr.autoname,
				returnType: returnType,
				parameterTypes: expr.analyzedParams.paramsAnalyzed.map { irType(for: $0.type) },
				isVarArg: false,
				captures: LLVM.StructType(
					name: expr.name ?? expr.autoname,
					types: expr.environment.captures.map { irType(for: $0.binding.type) })
			)

			functionType.name = expr.name ?? expr.autoname

			return functionType
		case let expr as AnalyzedVarExpr:
			return irType(for: expr.type)
		case let expr as AnalyzedDefExpr:
			return irType(for: expr.type)
		default:
			fatalError()
		}
	}

	func log(_ string: String) {
		if verbose {
			FileHandle.standardError.write(Data((string + "\n").utf8))
		}
	}
}
