//
//  TypedValue.swift
//
//
//  Created by Pat Nakajima on 7/18/24.
//
import C_LLVM
import TalkTalkSyntax
import TalkTalkTyper

extension ValueType {
	func llvmType(in context: LLVM.Context, bindings: Bindings) -> any LLVM.IRType {
		switch name {
		case "Int": .i32(context)
		case "Bool": .i1(context)
		case "Function":
			LLVM.FunctionType(
				context: context,
				returning: returns!.value.llvmType(in: context, bindings: bindings),
				parameters: parameters(context: context, bindings: bindings),
				isVarArg: false
			)
		case "Void": .void(context)
		default:
			fatalError("not handled")
		}
	}

	@available(*, deprecated, message: "It'd be nicer if more of this was provided by the syntax package")
	private func parameters(context: LLVM.Context, bindings: Bindings) -> [(String, any LLVM.IRType)] {
		guard let def = definition.as(FunctionDeclSyntax.self) else {
			return []
		}

		var result: [(String, any LLVM.IRType)] = []
		for parameter in def.parameters.parameters {
			result.append(
				(
					parameter.lexeme,
					bindings.type(for: parameter)!.llvmType(in: context, bindings: bindings)
				)
			)
		}
		return result
	}
}

extension TypedValue {
	func llvmType(in context: LLVM.Context, bindings: Bindings) -> any LLVM.IRType {
		type.llvmType(in: context, bindings: bindings)
	}
}
