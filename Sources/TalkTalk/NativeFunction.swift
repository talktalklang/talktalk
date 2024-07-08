//
//  Native.swift
//
//
//  Created by Pat Nakajima on 7/4/24.
//
enum Native {
	static let list: [String: any NativeFunction.Type] = [
		"println": NativeFunctionPrint.self,
		"_describe": NativeFunctionDescribe.self
	]
}

protocol NativeFunction: Equatable, Hashable {
	var name: String { get }
	var arity: Int { get }

	func call<Output: OutputCollector>(arguments: some Collection<Value>, in vm: inout VM<Output>) -> Value

	init()
}

final class NativeFunctionDescribe: NativeFunction {
	static func == (_: NativeFunctionDescribe, _: NativeFunctionDescribe) -> Bool {
		true
	}

	let name = "_describe"
	let arity = 1

	init() {}

	func call<Output: OutputCollector>(arguments: some Collection<Value>, in vm: inout VM<Output>) -> Value {
		return .string(arguments.first!.description)
	}

	func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(name)
	}
}

final class NativeFunctionPrint: NativeFunction {
	static func == (_: NativeFunctionPrint, _: NativeFunctionPrint) -> Bool {
		true
	}

	let name = "println"
	let arity = 1

	init() {}

	func call<Output: OutputCollector>(arguments: some Collection<Value>, in vm: inout VM<Output>) -> Value {
		let outputs = arguments.map { value in
			value.describe(in: &vm)
		}

		vm.output.print(outputs.joined(separator: ", "))
		return .nil
	}

	func hash(into hasher: inout Swift.Hasher) {
		hasher.combine(name)
	}
}
