//
//  Native.swift
//
//
//  Created by Pat Nakajima on 7/4/24.
//
final class Native {
	static let list: [String: any NativeFunction.Type] = [
		"print": NativeFunctionPrint.self,
	]
}

struct NativeEnvironment: Equatable {
	static func == (lhs: NativeEnvironment, rhs: NativeEnvironment) -> Bool {
		return type(of: lhs.output) == type(of: rhs.output)
	}

	var output: any OutputCollector
}

protocol NativeFunction: Equatable, Hashable {
	var name: String { get }
	var arity: Int { get }

	func call(arguments: some Sequence<Value>, in environment: inout NativeEnvironment) -> Value

	init()
}

final class NativeFunctionPrint: NativeFunction {
	static func == (_: NativeFunctionPrint, _: NativeFunctionPrint) -> Bool {
		true
	}

	let name = "print"
	let arity = 1

	init() {}

	func call(arguments: some Sequence<Value>, in environment: inout NativeEnvironment) -> Value {
		environment.output.print(arguments.map(\.description).joined(separator: ", "))
		return .nil
	}

	func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(name)
	}
}
