//
//  Environment.swift
//
//
//  Created by Pat Nakajima on 7/24/24.
//
import C_LLVM
import TalkTalkTyper

protocol StoringValue {
	func store(value: any LLVM.IRValue)
}

class HeapValues {
	var storage: [String: LLVM.HeapValue] = [:]

	subscript(_ name: String) -> LLVM.HeapValue? {
		get {
			storage[name]
		}

		set {
			if let newValue {
				storage[name] = newValue
			} else {
				storage[name] = nil
			}
		}
	}
}

class StackValues {
	var storage: [String: LLVM.StackValue] = [:]

	subscript(_ name: String) -> LLVM.StackValue? {
		get {
			storage[name]
		}

		set {
			if let newValue {
				storage[name] = newValue
			} else {
				storage[name] = nil
			}
		}
	}
}

class Environment {
	let name: String
	let parent: Environment?
	var emitter: LLVM.Emitter!
	let scope: Scope

	var heapValues: HeapValues
	var stackValues: StackValues

	var captureValues: [String: (Int, any LLVM.IRType)] = [:]
	var capturesStructType: LLVM.StructType!
	var capturesStruct: LLVM.HeapValue!

	var environmentParam: LLVMValueRef!

	init(name: String, parent: Environment?, scope: Scope, emitter: LLVM.Emitter? = nil) {
		self.name = name
		self.parent = parent
		self.scope = scope
		self.emitter = emitter

		self.heapValues = HeapValues()
		self.stackValues = StackValues()
	}

	func emitCaptures() -> LLVM.HeapValue {
		var types: [LLVMTypeRef?] = []
		var names: [String] = []

		captureValues = scope.captures().enumerated().reduce(into: [:]) { res, current in
			let (i, (name, binding)) = current

			guard binding.isEscaping else { return }

			let type = LLVM.PointerType(pointee: binding.type.toLLVM())

			// Store info for lookup later
			res[name] = (i, type)

			// Add the type to our list so we can use it to actually emit the struct
			types.append(type.ref)
			names.append(name)
		}

		// Create the struct type
		capturesStructType = LLVM.StructType(ref: LLVMStructCreateNamed(
			emitter.builder.module.context.ref,
			"Env_\(name)"
		)!)

		types.withUnsafeMutableBufferPointer {
			LLVMStructSetBody(
				capturesStructType.ref,
				$0.baseAddress,
				UInt32($0.count),
				.false
			)
		}

		// Store the struct as a pointer
		capturesStruct = emitter.malloc(capturesStructType, name: "Env_\(self.name)")

		// Set the values
		for (i, name) in names.enumerated() {
			if let value = parent?.pointer(to: name) {
				let ptr = LLVMBuildStructGEP2(
					emitter.builder.ref,
					capturesStructType.ref,
					capturesStruct.ref,
					UInt32(i),
					name
				)!

				emitter.store(value, in: ptr)
			}
		}

		return capturesStruct
	}

	func pointer(to identifier: String) -> LLVM.Pointer {
		if let stackValue = stackValues[identifier] {
			let pointerType = LLVM.PointerType(pointee: stackValue.type)
			return LLVM.Pointer(type: pointerType, ref: stackValue.ref)
		} else if let heapValue = heapValues[identifier] {
			let pointerType = LLVM.PointerType(pointee: heapValue.type)
			return LLVM.Pointer(type: pointerType, ref: heapValue.ref)
		} else if let (i, type) = captureValues[identifier] {
			let ptr = LLVMBuildStructGEP2(
				emitter.builder.ref,
				capturesStructType.ref,
				capturesStruct.ref,
				UInt32(i),
				identifier
			)!

			let pointerType = LLVM.PointerType(pointee: type)
			return LLVM.Pointer(type: pointerType, ref: ptr)
		}

		fatalError("Could not get pointer to: \(identifier)")
	}

	func emitEntry() {
		for (name, binding) in scope.locals {
			if binding.isEscaping {
				heapValues[name] = emitter.malloc(
					binding.type.toLLVM(in: emitter.builder.module.context),
					name: name
				)
			} else {
				stackValues[name] = emitter.alloca(
					binding.type.toLLVM(in: emitter.builder.module.context),
					name: name
				)
			}
		}
	}

	func lookup(identifier: String) -> any LLVM.IRValue {
		if let stackValue = stackValues[identifier] {
			return stackValue
		} else if let heapValue = heapValues[identifier] {
			return heapValue
		} else if let (i, type) = captureValues[identifier] {
			let ptr = LLVMBuildStructGEP2(
				emitter.builder.ref,
				capturesStructType.ref,
				environmentParam,
				UInt32(i),
				identifier
			)!

			return LLVM.Pointer(type: .init(pointee: type), ref: ptr)
		}

		fatalError("Could not find \(identifier) in environment")
	}
}
