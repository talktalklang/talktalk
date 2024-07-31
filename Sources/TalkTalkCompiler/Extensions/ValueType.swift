//
//  ValueType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import TalkTalkAnalysis
import LLVM

public extension ValueType {
	func irType(in builder: LLVM.Builder) -> any LLVM.IRType {
		switch self {
		case .int:
			return LLVM.IntType.i32
		case let .function(name, returns, params, captures):
			return LLVM.FunctionType(
				name: name,
				returnType: returns.irType(in: builder),
				parameterTypes: params.paramsAnalyzed.map { $0.type.irType(in: builder) },
				isVarArg: params.isVarArg,
				captures: LLVM.CapturesStructType(
					name: "\(name)Env", types: captures.map { $0.binding.type.irType(in: builder) }
				)
			)
		case let .struct(type):
			return type.toLLVM(in: builder, vtable: nil)
		case .none:
			return LLVM.VoidType()
		case let .instance(type):
			return type.irType(in: builder)
		default:
			fatalError()
		}
	}
}
