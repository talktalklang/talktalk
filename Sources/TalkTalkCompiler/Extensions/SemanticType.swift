//
//  SemanticType.swift
//
//
//  Created by Pat Nakajima on 7/22/24.
//

import TalkTalkTyper

extension FunctionType {
	func toLLVM(in context: LLVM.Context = .global, with environment: Environment) -> LLVM.FunctionType {
		let returning = if returns is FunctionType {
			// When the return type is a function, we want to return a pointer
			// to it instead of the function itself.
			LLVM.PointerType(pointee: returns.toLLVM(in: context))
		} else {
			returns.toLLVM(in: context)
		}

		var parameters = parameters.list.map {
			($0.name, $0.binding.type.toLLVM(in: context))
		}

		// Prepend the environment
		parameters.append((
			"Env_\(name)",
			LLVM.PointerType(pointee: environment.capturesStructType)
		))

		return LLVM.FunctionType(
			context: context,
			returning: returning,
			parameters: parameters,
			isVarArg: false
		)
	}
}

extension SemanticType {
	func toLLVM(in context: LLVM.Context = .global) -> any LLVM.IRType {
		switch self {
		case is IntType:
			return .i32(context)
		case is BoolType:
			return .bool(context)
		case let type as FunctionType:
			let returning = if type.returns is FunctionType {
				// When the return type is a function, we want to return a pointer
				// to it instead of the function itself.
				LLVM.PointerType(pointee: type.returns.toLLVM(in: context))
			} else {
				type.returns.toLLVM(in: context)
			}

			return LLVM.FunctionType(
				context: context,
				returning: returning,
				parameters: type.parameters.list.map {
					($0.name, $0.binding.type.toLLVM(in: context))
				},
				isVarArg: false
			)
		default:
			return .void(context)
		}
	}
}
