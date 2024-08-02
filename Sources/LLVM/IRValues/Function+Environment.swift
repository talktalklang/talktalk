//
//  Function+Environment.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM.Function {
	class Environment {
		public enum Binding {
			case declared(any LLVM.StoredPointer),
			     defined(any LLVM.StoredPointer),
			     parameter(Int, any LLVM.IRType),
			     capture(Int, LLVM.ClosureType),
					 builtin(String),
					 staticFunction(LLVM.FunctionType, LLVMValueRef),
					 closure(LLVM.ClosureType, LLVMValueRef),

					 // Struct bindings
					 structType(LLVM.StructType, LLVMValueRef),
					 `self`(LLVM.StructType),
					 getter(LLVM.StructType, any LLVM.IRType, String),
					 method(LLVM.StructType, LLVM.FunctionType, String)
		}

		var parent: Environment?

		public var envStructType: LLVM.StructType?

		// TODO: this ought not be public
		public var bindings: [String: Binding] = [:]

		public init(parent: Environment? = nil) {
			self.parent = parent
		}

		public func has(_ name: String) -> Bool {
			bindings[name] != nil
		}

		public func get(_ name: String) -> Binding? {
			// If it's in the current environment, we're good to go
			if let binding = bindings[name] {
				return binding
			}

			// If it's not, then we can't return params anymore
			if let binding = parent?.bindings[name] {
				return binding
			}

			if name == "printf" {
				return .builtin("printf")
			}

			return nil
		}

		public func type(of name: String) -> (any LLVM.IRType)? {
			guard case let .defined(pointer) = bindings[name] else {
				return nil
			}

			return pointer.type
		}

		public func parameter(_ name: String, type: any LLVM.IRType, at index: Int) {
			bindings[name] = .parameter(index, type)
		}

		public func define(_ name: String, as binding: Binding) {
			bindings[name] = binding
		}

		public func define(_ name: String, as value: any LLVM.StoredPointer) {
			bindings[name] = .defined(value)
		}

		public func declare(_ name: String, as value: any LLVM.StoredPointer) {
			bindings[name] = .declared(value)
		}

		public func defineType(_ structType: LLVM.StructType, pointer: LLVMValueRef) {
			bindings[structType.name] = .structType(structType, pointer)
		}

		public func defineFunction(_ name: String, type: LLVM.ClosureType, ref: LLVMValueRef) {
			bindings[name] = .closure(type, ref)
		}

		public func capture(_ name: String, with builder: LLVM.Builder) -> any LLVM.StoredPointer {
			switch get(name) {
			case let .declared(pointer):
				// If it's already on the heap, we can just keep using it
				if pointer.isHeap { return pointer }

				// If it's not, change the declaration to the heap
				let heapPointer = builder.malloca(type: pointer.type, name: name)
				declare(name, as: heapPointer)

				return heapPointer
			case let .defined(pointer):
				// If it's already on the heap, we can just keep using it
				if pointer.isHeap { return pointer }

				// If it's not, we need to move it to the heap and update our own use
				let heapPointer = builder.malloca(type: pointer.type, name: name)
				let currentValue = builder.load(pointer: pointer)
				_ = builder.store(currentValue, to: heapPointer)

				define(name, as: heapPointer)

				return heapPointer
			case let .parameter(index, type):
				let heapPointer = builder.malloca(type: type, name: name)
				let currentValue = builder.load(parameter: index)

				_ = builder.store(currentValue, to: heapPointer)
				define(name, as: heapPointer)

				return heapPointer
			default:
				if let parentCapture = parent?.capture(name, with: builder) {
					return parentCapture
				}
			}

			fatalError("Cannot capture \(name), doesn't exist in any parent environments.")
		}
	}
}
