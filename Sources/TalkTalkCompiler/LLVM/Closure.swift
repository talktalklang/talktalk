//
//  Closure.swift
//  
//
//  Created by Pat Nakajima on 7/24/24.
//

import C_LLVM

extension LLVM {
	class Closure {
		let name: String
		let function: Function
		let functionType: FunctionType
		let environment: Environment

		init(name: String, function: Function, type: FunctionType, environment: Environment) {
			self.name = name
			self.function = function
			self.functionType = type
			self.environment = environment
		}

		static func load(from pointer: Pointer, using emitter: Emitter) -> Closure {
			
		}

		func emit(into emitter: Emitter) -> Pointer {
			let context = emitter.builder.module.context.ref
			let builder = emitter.builder.ref

			// Save the type away
			let functionPointer = emitter.malloc(function.type, name: name, with: function)
			let environment = environment.emitCaptures()


			let environmentPointer = Pointer(type: .init(pointee: environment.type), ref: environment.ref)

			var values: [LLVMValueRef?] = [
				function.ref,
				environmentPointer.ref
			]

			let structAddress =  values.withUnsafeMutableBufferPointer {
				LLVMConstStructInContext(
					context,
					$0.baseAddress,
					3,
					.true
				)
			}!

			return .init(type: *function.type, ref: structAddress)
		}
	}
}
