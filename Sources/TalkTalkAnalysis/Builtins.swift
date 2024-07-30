//
//  Builtins.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 7/29/24.
//

public struct Builtin {
	public let name: String
	public let type: ValueType

	public static var print: Builtin {
		var paramsExpr: AnalyzedParamsExpr = [.int("value")]
		paramsExpr.isVarArg = true
		return Builtin(name: "printf", type: .function("printf", .int, paramsExpr, []))
	}
}
