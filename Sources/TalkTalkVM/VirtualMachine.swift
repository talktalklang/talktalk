//
//  VirtualMachine.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

import Foundation
import TalkTalkBytecode

public enum Verbosity: Equatable {
	case quiet, verbose
	case lineByLine(String)
}

public struct VirtualMachine {
	// The module to run. Must be compiled in executable mode.
	var module: Module

	// Should we print disassembled instructions/stack dumps on each tick
	var verbosity: Verbosity

	// Where should output go? (Defaults to stdout/stderr)
	var output: any OutputBuffer

	private var ip: Int

	// The chunk that's being run
	private var chunk: StaticChunk

	// The frames stack
	private var frames: Stack<CallFrame>

	// The current call frame
	private var currentFrame: CallFrame

	// The stack
	private var stack: Stack<Value>

	// A fake heap
	private var heap = Heap()

	// Closure storage
	private var closures: [StaticSymbol: Closure] = [:]

	private var globalValues: [StaticSymbol: Value] = [:]

	public static func run(module: Module, verbosity: Verbosity = .quiet, output: any OutputBuffer = DefaultOutputBuffer()) throws -> ExecutionResult {
		var vm = try VirtualMachine(module: module, verbosity: verbosity, output: output)
		return try vm.run()
	}

	public init(
		module: Module,
		verbosity: Verbosity = .quiet,
		output: any OutputBuffer = DefaultOutputBuffer()
	) throws {
		self.module = module
		self.verbosity = verbosity
		self.output = output

		guard let chunk = module.main else {
			throw VirtualMachineError.mainNotFound("no entrypoint found for module `\(module.name)`")
		}

		self.stack = Stack<Value>(capacity: 2048)
		self.frames = Stack<CallFrame>(capacity: 2048)

		let frame = CallFrame(
			closure: Closure(chunk: chunk, capturing: [:]),
			returnTo: 0,
			selfValue: nil,
			stackOffset: stack.size
		)

		try frames.push(frame)

		self.currentFrame = frame
		self.chunk = frame.closure.chunk
		self.ip = 0
	}

	private mutating func restoreCurrentFrame(returnTo: Int) throws {
		// Return to where we called from
		#if DEBUG
			log("       <- \(chunk.name), depth: \(chunk.depth) locals: \(chunk.locals)")
		#endif

		if frames.size == 0 { return }

		currentFrame = try frames.peek()
		chunk = currentFrame.closure.chunk
		ip = returnTo

		#if DEBUG
			log("       -> \(chunk.name), depth: \(chunk.depth) locals: \(chunk.locals)")
		#endif
	}

	public mutating func run() throws -> ExecutionResult {
		let start = Date()

		while true {
			#if DEBUG
				func dumpInstruction() throws -> Instruction? {
					var disassembler = Disassembler(chunk: chunk, module: module)
					disassembler.current = ip
					if let instruction = try disassembler.next() {
						dumpStack()
						dumpLocals()
						instruction.dump()
						return instruction
					}
					return nil
				}

				switch verbosity {
				case .quiet:
					()
				case .verbose:
					_ = try dumpInstruction()
				case let .lineByLine(string):
					if let i = try dumpInstruction() {
						if i.line < string.components(separatedBy: .newlines).count {
							let line = string.components(separatedBy: .newlines)[Int(i.line)]
							FileHandle.standardError.write(Data(("       " + line + "\n").utf8))
						} else {
							var line = ""
							if let url = URL(string: "file://" + i.path),
							   let filelines = try? String(contentsOf: url).components(separatedBy: .newlines)
							{
								line = filelines[Int(i.line)] + " "
							}
							FileHandle.standardError.write(Data("        \(line)<\(i.path.components(separatedBy: "/").last ?? i.path):\(i.line)>\n".utf8))
						}
					}
				}
			#endif

			let opcode = try readOpcode()

			switch opcode {
			case .returnVoid:
				var calledFrame = try frames.pop()
				while calledFrame.isInline {
					calledFrame = try frames.pop()
				}

				try restoreCurrentFrame(returnTo: calledFrame.returnTo)

				// If there are no frames left, we're done.
				if frames.size == 0 {
					// Make sure we didn't leak anything, we should only have the main program
					// on the stack.
					if verbosity == .verbose {
						if stack.size != 0 {
							print("stack size expected to be 0, got: \(stack.size)")
							dumpStack()
						}
					}

					return .ok(.`nil`, Date().timeIntervalSince(start))
				}

				try transferCaptures(in: calledFrame)

				while stack.size > calledFrame.stackOffset + 1 {
					try stack.pop()
				}
			case .returnValue:
				var calledFrame = try frames.pop()

				// If there are no frames left, we're done.
				if frames.size == 0 {
					// Make sure we didn't leak anything, we should only have the main program
					// on the stack.
					if verbosity == .verbose {
						if stack.size != 0 {
							print("stack size expected to be 0, got: \(stack.size)")
							dumpStack()
						}
					}

					let retVal = stack.size == 0 ? .`nil` : try stack.pop()

					return .ok(retVal, Date().timeIntervalSince(start))
				}

				// Remove the result from the stack temporarily while we clean it up
				let result = try stack.pop()

				while stack.size > calledFrame.stackOffset + 1 {
					try stack.pop()
				}

				while calledFrame.isInline {
					calledFrame = try frames.pop()
				}

				try restoreCurrentFrame(returnTo: calledFrame.returnTo)

				try transferCaptures(in: calledFrame)

				// Push the result back onto the stack
				try stack.push(result)
			case .suspend:
				return try .ok(stack.peek(), Date().timeIntervalSince(start))
			case .constant:
				let value = try readConstant()
				try stack.push(value)
			case .true:
				try stack.push(.bool(true))
			case .false:
				try stack.push(.bool(false))
			case .none:
				try stack.push(.`nil`)
			case .primitive:
				let byte = try readByte()

				guard let primitive = Primitive(rawValue: byte) else {
					throw VirtualMachineError.valueMissing("No primitive found for byte: \(byte)")
				}

				try stack.push(.primitive(primitive))
			case .negate:
				let value = try stack.pop()
				if let intValue = value.intValue {
					try stack.push(.int(-intValue))
				} else {
					return runtimeError("Cannot negate \(value)")
				}
			case .and:
				let rhs = try stack.pop()
				let lhs = try stack.pop()

				switch (lhs, rhs) {
				case let (.bool(lhs), .bool(rhs)):
					try stack.push(.bool(lhs && rhs))
				default:
					return runtimeError("&& requires bool operands. got \(lhs) & \(rhs)")
				}
			case .not:
				let value = try stack.pop()
				if let bool = value.boolValue {
					try stack.push(.bool(!bool))
				}
			case .match:
				let pattern = try stack.pop()
				let target = try stack.pop()

				func bind(_ pattern: Value, to target: Value) {
					if case let .boundEnumCase(pattern) = pattern,
					   case let .boundEnumCase(target) = target
					{
						for (i, value) in pattern.values.enumerated() {
							switch value {
							case .binding:
								if case let .binding(binding) = pattern.values[i] {
									binding.value = target.values[i]
								}
							case let .boundEnumCase(pattern):
								bind(.boundEnumCase(pattern), to: target.values[i])
							default:
								()
							}
						}
					}
				}

				bind(pattern, to: target)
				try stack.push(.bool(pattern == target))
			case .equal:
				let lhs = try stack.pop()
				let rhs = try stack.pop()

				try stack.push(.bool(lhs == rhs))
			case .notEqual:
				let lhs = try stack.pop()
				let rhs = try stack.pop()
				try stack.push(.bool(lhs != rhs))
			case .add:
				let lhsValue = try stack.pop()
				let rhsValue = try stack.pop()

				switch (lhsValue, rhsValue) {
				case let (.int(lhs), .int(rhs)):
					try stack.push(.int(lhs + rhs))
				case let (.string(lhs), .string(rhs)):
					try stack.push(.string(lhs + rhs))
				case let (.pointer(pointer), .int(rhs)):
					try stack.push(.pointer(pointer + rhs))
				case let (.data(lhs), .data(rhs)):
					let lhs = chunk.data[Int(lhs)]
					let rhs = chunk.data[Int(rhs)]

					guard lhs.kind == .string, lhs.kind == .string else {
						return runtimeError("Cannot add two data operands: \(lhs), \(rhs)")
					}

					let bytes = lhs.bytes + rhs.bytes
					let pointer = heap.allocate(count: bytes.count)

					for i in 0 ..< bytes.count {
						heap.store(pointer: pointer + i, value: Value.byte(bytes[i]))
					}

					try stack.push(.pointer(pointer))
				default:
					return runtimeError("Cannot add \(lhsValue) & \(rhsValue) operands")
				}
			case .subtract:
				let lhs = try stack.pop()
				let rhs = try stack.pop()

				guard let lhs = lhs.intValue,
				      let rhs = rhs.intValue
				else {
					return runtimeError("Cannot subtract \(lhs) & \(rhs) operands")
				}
				try stack.push(.int(lhs - rhs))
			case .modulo:
				let lhs = try stack.pop()
				let rhs = try stack.pop()

				guard let lhs = lhs.intValue,
							let rhs = rhs.intValue
				else {
					return runtimeError("Cannot modulo \(lhs) & \(rhs) operands")
				}
				try stack.push(.int(lhs % rhs))
			case .divide:
				let lhs = try stack.pop()
				let rhs = try stack.pop()

				guard let lhs = lhs.intValue,
				      let rhs = rhs.intValue
				else {
					return runtimeError("Cannot divide \(lhs) & \(rhs) operands")
				}

				if rhs == 0 {
					return runtimeError("Cannot divide by zero.")
				}

				try stack.push(.int(lhs / rhs))
			case .multiply:
				let lhs = try stack.pop()
				let rhs = try stack.pop()

				guard let lhs = lhs.intValue,
				      let rhs = rhs.intValue
				else {
					return runtimeError("Cannot multiply \(lhs) & \(rhs) operands")
				}
				try stack.push(.int(lhs * rhs))
			case .less:
				let lhs = try stack.pop()
				let rhs = try stack.pop()

				guard let lhs = lhs.intValue,
				      let rhs = rhs.intValue
				else {
					return runtimeError("Cannot compare \(lhs) & \(rhs) operands")
				}
				try stack.push(.bool(lhs < rhs))
			case .greater:
				let lhs = try stack.pop()
				let rhs = try stack.pop()

				guard let lhs = lhs.intValue,
				      let rhs = rhs.intValue
				else {
					return runtimeError("Cannot compare \(lhs) & \(rhs) operands")
				}
				try stack.push(.bool(lhs > rhs))
			case .lessEqual:
				let lhs = try stack.pop()
				let rhs = try stack.pop()

				guard let lhs = lhs.intValue,
				      let rhs = rhs.intValue
				else {
					return runtimeError("Cannot compare \(lhs) & \(rhs) operands")
				}
				try stack.push(.bool(lhs <= rhs))
			case .greaterEqual:
				let lhs = try stack.pop()
				let rhs = try stack.pop()

				guard let lhs = lhs.intValue,
				      let rhs = rhs.intValue
				else {
					return runtimeError("Cannot compare \(lhs) & \(rhs) operands")
				}
				try stack.push(.bool(lhs >= rhs))
			case .data:
				let slot = try readByte()
				let data = chunk.data[Int(slot)]
				switch data.kind {
				case .string:
					try stack.push(.string(String(data: Data(data.bytes), encoding: .utf8) ?? "<invalid string>"))
				}
			case .pop:
				try stack.pop()
			case .loop:
				ip -= try readUInt16()
			case .jump:
				ip += try readUInt16()
			case .jumpUnless:
				let jump = try readUInt16()
				if try stack.peek() == .bool(false) {
					ip += jump
				}
			case .getLocal:
				let symbol = try readSymbol()

				if symbol.name == "self" {
					guard let selfValue = currentFrame.selfValue else {
						throw VirtualMachineError.valueMissing("did not find self for \(symbol)")
					}

					try stack.push(selfValue)

					continue
				}

				guard let local = currentFrame.lookup(symbol) else {
					throw VirtualMachineError.valueMissing("did not find local for \(symbol)")
				}

				// Unwrap bindings if they have values
				if case let .binding(binding) = local, let value = binding.value {
					try stack.push(value)
				} else {
					try stack.push(local)
				}
			case .setLocal:
				let symbol = try readSymbol()
				try currentFrame.define(symbol, as: stack.peek())
			case .getCapture:
				let capture = try readCapture()

				switch currentFrame.closure.capturing[capture.symbol] {
				case let .stack(depth):
					let frame = try frames.peek(offset: depth)

					guard let value = frame.lookup(capture.symbol) else {
						throw VirtualMachineError.valueMissing("Capture named `\(capture.symbol)` not found in call frame stack")
					}

					try stack.push(value)
				case let .heap(base, offset):
					guard let value = heap.dereference(pointer: .init(base: base, offset: offset)) else {
						throw VirtualMachineError.valueMissing("Capture named `\(capture.symbol)` not found on heap")
					}

					try stack.push(value)
				default:
					throw VirtualMachineError.valueMissing("Capture named `\(capture.symbol)` not found in closure")
				}
			case .setCapture:
				let capture = try readCapture()

				switch currentFrame.closure.capturing[capture.symbol] {
				case let .stack(depth):
					try frames[frames.size - depth - 1].define(capture.symbol, as: stack.peek())
				case let .heap(base, offset):
					try heap.store(pointer: .init(base: base, offset: offset), value: stack.peek())
				default:
					throw VirtualMachineError.valueMissing("Capture named `\(capture.symbol)` not found in closure")
				}
			case .defClosure:
				// Read which subchunk this closure points to
				let symbol = try readSymbol()

				// Load the subchunk TODO: We could probably just store the index in the closure?
				guard let subchunk = module.chunks[symbol] else {
					throw VirtualMachineError.valueMissing("no chunk found for symbol: \(symbol)")
				}

				// Push the closure Value onto the stack
				try stack.push(.closure(symbol))

				currentFrame.define(symbol, as: .closure(symbol))

				let capturing: [StaticSymbol: Capture.Location] = subchunk.capturing.reduce(into: [:]) { res, capture in
					res[capture.symbol] = capture.location
				}

				// Store the closure TODO: gc these when they're not needed anymore
				closures[symbol] = Closure(chunk: subchunk, capturing: capturing)
			case .call:
				let callee = try stack.pop()
				try call(callee)
			case .callChunkID:
				let symbol = try readSymbol()
				try call(chunkID: symbol)
			case .getModuleFunction:
				let symbol = try readSymbol()
				let moduleFunction = Value.moduleFunction(symbol)
				try stack.push(moduleFunction)
			case .setModuleFunction:
				return runtimeError("cannot set module functions")
			case .getModuleValue:
				let symbol = try readSymbol()
				if let global = globalValues[symbol] {
					try stack.push(global)
				} else if let initializer = module.valueInitializers[symbol] {
					// If we don't have the global already, we lazily initialize it by running its initializer
					try call(chunk: initializer)
				} else {
					return runtimeError("No global found at slot: \(symbol)")
				}
			case .setModuleValue:
				let symbol = try readSymbol()
				globalValues[symbol] = try stack.peek()

				// Remove the lazy initializer for this value since we've already initialized it
				module.valueInitializers.removeValue(forKey: symbol)
			case .getBuiltin:
				let builtin = try readSymbol()
				try stack.push(.builtin(builtin))
			case .setBuiltin:
				return runtimeError("Cannot set built in")
			case .getBuiltinStruct:
				let slot = try readByte()
				try stack.push(.builtinStruct(.init(slot)))
			case .setBuiltinStruct:
				return runtimeError("Cannot set built in")
			case .cast:
				let symbol = try readSymbol()

				guard let structValue = module.structs[symbol] else {
					throw VirtualMachineError.valueMissing("no struct for value: \(symbol)")
				}

				try call(structValue: structValue)
			case .getStruct:
				let symbol = try readSymbol()

				guard let structType = module.structs[symbol] else {
					throw VirtualMachineError.valueMissing("no struct for value: \(symbol)")
				}

				try stack.push(.struct(structType))
			case .setStruct:
				return runtimeError("Cannot set struct")
			case .invokeMethod:
				let receiver = try stack.pop()
				let method = try readSymbol()

				if case let .instance(instance) = receiver {
					try call(boundMethod: method, on: instance)
				} else if case let .enumCase(enumCase) = receiver {
					try call(boundMethod: method, on: enumCase)
				} else {
					return runtimeError("invalid receiver for method invocation: \(receiver), method: \(method)")
				}
			case .getMethod:
				// Get the slot of the member
				let symbol = try readSymbol()

				// Pop the receiver off the stack
				let receiver = try stack.pop()

				switch receiver {
				case let .instance(instance):
					try stack.push(.boundStructMethod(instance, symbol))
				case let .enumCase(value):
					try stack.push(.boundEnumMethod(value, symbol))
				default:
					return runtimeError("Receiver is not an instance")
				}
			case .getProperty:
				// Get the slot of the member
				var symbol = try readSymbol()

				// Pop the receiver off the stack
				let receiver = try stack.pop()

				switch receiver {
				case let .instance(instance):
					if symbol.params != nil, let name = symbol.name {
						symbol = .property(symbol.module, instance.type.name, name)
					}

					guard let value = instance.fields[symbol] else {
						return runtimeError("uninitialized value in slot \(symbol) for \(instance)")
					}

					try stack.push(value)
				case let .enum(value):
					if symbol.params != nil, let name = symbol.name {
						symbol = .property(symbol.module, value.name, name)
					}

					guard let value = value.cases[symbol] else {
						return runtimeError("uninitialized value in slot \(symbol) for \(value)")
					}

					try stack.push(.enumCase(value))
				default:
					return runtimeError("Receiver is not an instance")
				}
			case .is:
				let lhs = try stack.pop()
				let rhs = try stack.pop()

				try checkType(instance: lhs, type: rhs)
			case .setProperty:
				let symbol = try readSymbol()
				let instance = try stack.pop()
				let propertyValue = try stack.pop()

				guard let receiver = instance.instanceValue else {
					return runtimeError("Receiver is not a struct: \(instance)")
				}

				// Set the property
				receiver.fields[symbol] = propertyValue
			// Put the updated instance back onto the stack
//				stack[stack.size - 1] = .instance(receiver)
			case .jumpPlaceholder:
				()
			case .get:
				let instance = try stack.pop()
				guard let receiver = instance.instanceValue else {
					return runtimeError("Receiver is not a struct: \(instance)")
				}

				let method = try readSymbol()

				try call(
					boundMethod: method,
					on: receiver
				)
			case .initArray:
				let count = try readByte()

				// We need to set the capacity to at least 1 or else trying to resize it will multiply 0 by 2
				// which means we never actually get more capacity.
				let capacity = max(count, 1)

				guard let arrayType = module.structs[Symbol.struct("Standard", "Array").asStatic()] else {
					throw VirtualMachineError.valueMissing("No Array type found")
				}

				let pointer = heap.allocate(count: Int(capacity))
				for i in 0 ..< count {
					try heap.store(pointer: pointer + Int(i), value: stack.pop())
				}

				let instance = Instance(type: arrayType, fields: [
					Symbol.property("Standard", "Array", "_storage").asStatic(): .pointer(pointer),
					Symbol.property("Standard", "Array", "count").asStatic(): .int(.init(count)),
					Symbol.property("Standard", "Array", "capacity").asStatic(): .int(.init(capacity)),
				])

				try stack.push(.instance(instance))
			case .initDict:
				guard let arrayType = module.structs[Symbol.struct("Standard", "Array").asStatic()] else {
					throw VirtualMachineError.valueMissing("No Array type found")
				}

				guard let dictType = module.structs[Symbol.struct("Standard", "Dictionary").asStatic()] else {
					throw VirtualMachineError.valueMissing("No Dictionary type found")
				}

				guard let entryType = module.structs[Symbol.struct("Standard", "DictionaryEntry").asStatic()] else {
					throw VirtualMachineError.valueMissing("No DictionaryEntry type found")
				}

				let count = try readByte()
				let capacity = max(count, 1)
				let entriesArrayPointer = heap.allocate(count: Int(capacity))

				for i in 0 ..< Int(count) {
					let value = try stack.pop()
					let key = try stack.pop()
					let instance = Instance(type: entryType, fields: [
						Symbol.property("Standard", "DictionaryEntry", "key").asStatic(): key,
						Symbol.property("Standard", "DictionaryEntry", "value").asStatic(): value,
					])

					heap.store(pointer: entriesArrayPointer + i, value: .instance(instance))
				}

				let entriesArray = Instance(type: arrayType, fields: [
					Symbol.property("Standard", "Array", "_storage").asStatic(): .pointer(entriesArrayPointer),
					Symbol.property("Standard", "Array", "count").asStatic(): .int(.init(count)),
					Symbol.property("Standard", "Array", "capacity").asStatic(): .int(.init(capacity)),
				])

				let dictInstance = Instance(type: dictType, fields: [
					Symbol.property("Standard", "Dictionary", "storage").asStatic(): .instance(entriesArray),
				])

				try stack.push(.instance(dictInstance))
			case .binding:
				let sym = try readSymbol()
				if let binding = currentFrame.patternBindings[sym] {
					try stack.push(binding)
				} else {
					let binding: Value = .binding(.new())
					currentFrame.patternBindings[sym] = binding
					try stack.push(binding)
				}
			case .endInline:
				let frame = try frames.peek()
				if frame.isInline {
					try frames.pop()
					try restoreCurrentFrame(returnTo: frame.returnTo)
				}
			case .beginScope:
				()
			case .matchBegin:
				let symbol = try readSymbol()
				try call(chunkID: symbol, inline: true)
			case .matchCase:
				let jump = try readUInt16()
				if try stack.peek() == .bool(true) {
					ip += jump
				}
			case .getEnum:
				let sym = try readSymbol()

				guard let enumType = module.enums[sym] else {
					throw VirtualMachineError.valueMissing("No enum found for symbol: \(sym)")
				}

				try stack.push(.enum(enumType))
			case .debugPrint:
				_ = try readByte()
			case .appendInterpolation:
				let new = try stack.pop()
				let old = try stack.pop()
				try stack.push(.string(inspect(old) + inspect(new)))
			case .noop:
				()
			}
		}
	}

	public mutating func set(chunk: StaticChunk) {
		self.chunk = chunk
	}

	private mutating func checkType(instance: Value, type: Value) throws {
		try stack.push(.bool(instance.is(type)))
	}

	private mutating func call(_ callee: Value) throws {
		switch callee {
		case let .closure(chunkID):
			try call(closureID: chunkID)
		case let .builtin(builtin):
			try call(builtin: builtin)
		case let .moduleFunction(moduleFunction):
			try call(chunkID: moduleFunction)
		case let .struct(structValue):
			try call(structValue: structValue)
		case let .boundStructMethod(instance, symbol):
			try call(boundMethod: symbol, on: instance)
		case let .enumCase(callee):
			try bind(enum: callee)
		case let .boundEnumMethod(enumCase, symbol):
			try call(boundMethod: symbol, on: enumCase)
		default:
			throw VirtualMachineError.typeError("\(callee) is not callable")
		}
	}

	private mutating func bind(enum enumCase: EnumCase) throws {
		try stack.push(
			.boundEnumCase(
				BoundEnumCase(
					type: enumCase.type,
					name: enumCase.name,
					values: stack.pop(count: enumCase.arity).reversed()
				)
			)
		)
	}

	@inline(__always)
	private mutating func pushFrame(_ frame: CallFrame) throws {
		try frames.push(frame)

		ip = 0
		currentFrame = frame
		chunk = frame.closure.chunk
	}

	// Call a method on a struct instance.
	// Takes the method offset, instance and type that defines the method.
	@inline(__always)
	private mutating func call(boundMethod: StaticSymbol, on instance: Instance) throws {
		var boundMethod = boundMethod

		if let name = boundMethod.name, let params = boundMethod.params {
			boundMethod = Symbol(module: boundMethod.module, kind: .method(instance.type.name, name, params)).asStatic()
		}

		guard let methodChunk = module.chunks[boundMethod] else {
			throw VirtualMachineError.valueMissing("no method found \(boundMethod)")
		}

		try call(chunk: methodChunk, withSelf: .instance(instance), additionalOffset: 1)
	}

	// Call a method on a struct instance.
	// Takes the method offset, instance and type that defines the method.
	@inline(__always)
	private mutating func call(boundMethod: StaticSymbol, on enumCase: EnumCase) throws {
		var boundMethod = boundMethod

		if let name = boundMethod.name, let params = boundMethod.params {
			boundMethod = Symbol(module: boundMethod.module, kind: .method(enumCase.type, name, params)).asStatic()
		}

		guard let methodChunk = module.chunks[boundMethod] else {
			throw VirtualMachineError.valueMissing("no method found \(boundMethod)")
		}

		try call(chunk: methodChunk, withSelf: .enumCase(enumCase))
	}

	@inline(__always)
	private mutating func call(structValue structType: Struct) throws {
		// Create the instance Value
		let instance = Value.instance(
			Instance(
				type: structType,
				fields: [:]
			)
		)

		// Get the initializer
		guard let symbol = structType.initializer, let initializer = module.chunks[symbol] else {
			throw VirtualMachineError.valueMissing("no initializer found for \(structType.name)")
		}

		try call(chunk: initializer, withSelf: instance)
	}

	@inline(__always)
	private mutating func call(chunk: StaticChunk, withSelf: Value? = nil, additionalOffset: Int = 0) throws {
		let frame = CallFrame(
			closure: .init(
				chunk: chunk,
				capturing: [:]
			),
			returnTo: ip,
			selfValue: withSelf,
			stackOffset: stack.size - additionalOffset
		)

		let args = try stack.pop(count: Int(chunk.arity))
		for i in 0 ..< Int(chunk.arity) {
			frame.define(chunk.locals[i], as: args[i])
		}

		try pushFrame(frame)
	}

	@inline(__always)
	private mutating func call(closureID: StaticSymbol) throws {
		// Find the called chunk from the closure id
		guard let closure = closures[closureID] else {
			throw VirtualMachineError.valueMissing("No closure with id \(closureID)")
		}

		let frame = CallFrame(
			closure: closure,
			returnTo: ip,
			selfValue: currentFrame.selfValue,
			stackOffset: stack.size
		)

		let args = try stack.pop(count: Int(closure.chunk.arity))
		for i in 0 ..< Int(closure.chunk.arity) {
			frame.define(closure.chunk.locals[i], as: args[i])
		}

		try pushFrame(frame)
	}

	@inline(__always)
	private mutating func call(chunkID: StaticSymbol, inline: Bool = false) throws {
		guard let chunk = module.chunks[chunkID] else {
			throw VirtualMachineError.valueMissing("No chunk found for symbol: \(chunkID)")
		}

		let capturing: [StaticSymbol: Capture.Location] = chunk.capturing.reduce(into: [:]) { res, capture in
			res[capture.symbol] = capture.location
		}

		let closure = Closure(chunk: chunk, capturing: capturing)

		let frame = CallFrame(
			closure: closure,
			returnTo: ip,
			selfValue: currentFrame.selfValue,
			stackOffset: stack.size
		)

		frame.isInline = inline

		let args = try stack.pop(count: Int(chunk.arity))
		for i in 0 ..< Int(chunk.arity) {
			frame.define(chunk.locals[i], as: args[i])
		}

		try pushFrame(frame)
	}

	private func inspect(_ value: Value) -> String {
		switch value {
		case let .string(string):
			string
		case let .int(int):
			"\(int)"
		default:
			value.description
		}
	}

	private mutating func call(builtin: StaticSymbol) throws {
		switch builtin.name {
		case "print":
			let value = try stack.pop()
			let string = inspect(value) + "\n"
			try output.write([Byte](Data(string.utf8)), to: .stdout)
		case "_allocate":
			if case let .int(count) = try stack.pop() { // Get the capacity
				let pointer = heap.allocate(count: Int(count))
				try stack.push(.pointer(pointer))
			}
		case "_deref":
			guard case let .pointer(pointer) = try stack.pop() else {
				throw VirtualMachineError.typeError("cannot dereference non-pointer")
			}

			guard let value = heap.dereference(pointer: pointer) else {
				throw VirtualMachineError.valueMissing("no value found for pointer \(pointer)")
			}

			try stack.push(value)
		case "_free":
			try stack.pop()
			() // TODO:
		case "_storePtr":
			let value = try stack.pop()
			let pointer = try stack.pop()
			if case let .pointer(pointer) = pointer {
				heap.store(pointer: pointer, value: value)
			} else {
				throw VirtualMachineError.typeError("expected pointer, got \(pointer)")
			}
		case "_hash":
			let value = try stack.pop()
			try stack.push(.int(.init(value.hashValue)))
		case "_cast":
			() // This is just for the analyzer
		default:
			throw VirtualMachineError.valueMissing("unknown builtin: \(builtin)")
		}
	}

	@inline(__always)
	private mutating func transferCaptures(in calledFrame: CallFrame) throws {
		let capturedLocals = calledFrame.closure.chunk.capturedLocals
		// Take locals from the popped frame, put them on the heap, then update captures to
		// point to the new location. This is sort of doing a lot of work that could probably
		// happen elsewhere but like, closures are really none of my business tbh.
		for local in capturedLocals {
			guard let value = calledFrame.lookup(local) else {
				throw VirtualMachineError.valueMissing("missing local for capture: \(local)")
			}

			let pointer = heap.allocate(count: 1)
			heap.store(pointer: pointer, value: value)

			for (sym, _) in closures {
				closures[sym]?.capturing[local] = .heap(pointer.base, pointer.offset)
			}
		}
	}

	@inline(__always)
	private mutating func readConstant() throws -> Value {
		let value = try chunk.constants[Int(readByte())]
		return value
	}

	@inline(__always)
	private mutating func readByte() throws -> Byte {
		defer { ip += 1 }
		return try chunk.code[Int(ip)].asByte()
	}

	@inline(__always)
	private mutating func readOpcode() throws -> Opcode {
		defer { ip += 1 }
		return try chunk.code[Int(ip)].asOpcode()
	}

	@inline(__always)
	private mutating func readCapture() throws -> Capture {
		defer { ip += 1 }
		return try chunk.code[Int(ip)].asCapture()
	}

	@inline(__always)
	private mutating func readSymbol() throws -> StaticSymbol {
		defer { ip += 1 }
		return try chunk.code[ip].asSymbol()
	}

	@inline(__always)
	private mutating func readUInt16() throws -> Int {
		var jump = try Int(readByte() << 8)
		jump |= try Int(readByte())
		return jump
	}

	private func runtimeError(_ message: String) -> ExecutionResult {
		.error(message)
	}

	private func dumpLocals() {
		var result = "       Locals: "

		for local in currentFrame.locals {
			result += "[ \(local.key) = \(local.value) ]"
		}

		if !currentFrame.patternBindings.isEmpty {
			result += "\n       Pattern bindings: "
			result += currentFrame.patternBindings.map { "[ \($0) ]" }.joined(separator: ", ")
		}

		if let selfValue = currentFrame.selfValue {
			result += "\n       self: \(selfValue)"
		}

		FileHandle.standardError.write(Data((result + "\n").utf8))
	}

	@discardableResult private mutating func dumpStack() -> String {
		if stack.isEmpty { return "" }
		var result = "       Stack: "

		for slot in stack.entries() {
			if frames.size == 0 {
				result += "[ \(slot.description) ]"
			} else {
				result += "[ \(slot.disassemble(in: module)) ]"
			}
		}

		FileHandle.standardError.write(Data((result + "\n").utf8))

		return result
	}

	private mutating func dump() throws {
		var disassembler = Disassembler(chunk: chunk, module: module)
		for instruction in try disassembler.disassemble() {
			let prefix = instruction.offset == ip ? "> " : "  "
			print(prefix + instruction.description)

			if instruction.offset == ip {
				dumpStack()
			}
		}
	}

	private func log(_ string: String) {
		if verbosity != .quiet {
			FileHandle.standardError.write(Data((string + "\n").utf8))
		}
	}
}
