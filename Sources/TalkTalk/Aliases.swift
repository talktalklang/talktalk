//
//  Aliases.swift
//  
//
//  Created by Pat Nakajima on 6/30/24.
//

typealias Byte = UInt8

func printf(_ string: String, _ args: CVarArg...) {
	print(String(format: string, args), terminator: "")
}

func print(format string: String, _ args: CVarArg...) {
	print(String(format: string, args))
}
