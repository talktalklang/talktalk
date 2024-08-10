//
//  ValueType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/30/24.
//

import LLVM
import TalkTalkAnalysis

public extension ValueType {
	func irType(in builder: LLVM.Builder) -> any LLVM.IRType {
		switch self {
		case .int:
			return LLVM.IntType.i32
		case let .function(name, returns, params, captures):
			let fnType = LLVM.FunctionType(
				name: name,
				returnType: returns.irType(in: builder),
				parameterTypes: params.paramsAnalyzed.map { $0.type.irType(in: builder) },
				isVarArg: params.isVarArg,
				capturedTypes: captures.map { $0.binding.type.irType(in: builder) }
			)

			return LLVM.ClosureType(functionType: fnType, captureTypes: captures.map { $0.binding.type.irType(in: builder) })
		case let .struct(type):
			return type.toLLVM(in: builder)
		case .none:
			return LLVM.VoidType()
		case let .instance(type):
			return type.irType(in: builder)
		default:
			fatalError("no ir type for \(self)")
		}
	}
}
