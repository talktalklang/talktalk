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

	var ip: UInt64

	// The chunk that's being run
	var chunk: StaticChunk

	// The frames stack
	var frames: Stack<CallFrame> {
		willSet {
			#if DEBUG
				if frames.size != newValue.size, frames.size > 0, verbosity != .quiet {
					log("       <- \(chunk.name), depth: \(chunk.depth) locals: \(chunk.locals)")
				}
			#endif
		}

		didSet {
			ip = 0
			if frames.isEmpty { return }

			do {
				currentFrame = try frames.peek()
				chunk = currentFrame.closure.chunk

				#if DEBUG
					if frames.size != oldValue.size, frames.size > 0, verbosity != .quiet {
						log("       -> \(chunk.name), depth: \(chunk.depth) locals: \(chunk.locals)")
					}
				#endif
			} catch {
				print("Frames in invalid state! \(error)")
			}
		}
	}

	// The current call frame
	var currentFrame: CallFrame

	// The stack
	var stack: Stack<Value>

	// A fake heap
	var heap = Heap()

	// Closure storage
	var closures: [Symbol: Closure] = [:]

	var globalValues: [Symbol: Value] = [:]

	// Upvalue linked list
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

	public mutating func run() throws -> ExecutionResult {
		let start = Date()

		while true {
			#if DEBUG
				func dumpInstruction() throws -> Instruction? {
					var disassembler = Disassembler(chunk: chunk, module: module)
					disassembler.current = Int(ip)
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

					return .ok(.none, Date().timeIntervalSince(start))
				}

				try transferCaptures(in: calledFrame)

				while stack.size > calledFrame.stackOffset + 1 {
					try stack.pop()
				}

				// Return to where we called from
				ip = calledFrame.returnTo
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

					let retVal = stack.size == 0 ? .none : try stack.pop()

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

				try transferCaptures(in: calledFrame)

				// Push the result back onto the stack
				try stack.push(result)

				// Return to where we called from
				ip = calledFrame.returnTo
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
				try stack.push(.none)
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

				if case .value("self") = symbol.kind {
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
				case let .heap(pointer):
					guard let value = heap.dereference(pointer: pointer) else {
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
				case let .heap(pointer):
					try heap.store(pointer: pointer, value: stack.peek())
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

				let capturing: [Symbol: Capture.Location] = subchunk.capturing.reduce(into: [:]) { res, capture in
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
			case .getProperty:
				// Get the slot of the member
				var symbol = try readSymbol()

				// PropertyOptions let us see if this member is a method
				let propertyOptions = try PropertyOptions(rawValue: readByte())

				// Pop the receiver off the stack
				let receiver = try stack.pop()

				switch receiver {
				case let .instance(instance):
					if propertyOptions.contains(.isMethod) {
						// If it's a method, we create a boundMethod value, which consists of the method symbol
						// and the instance ID.
						let boundMethod = Value.boundStructMethod(instance, symbol)

						try stack.push(boundMethod)
					} else {
						if case let .property(nil, name) = symbol.kind {
							symbol = .property(symbol.module, instance.type.name, name)
						}

						guard let value = instance.fields[symbol] else {
							return runtimeError("uninitialized value in slot \(symbol) for \(instance)")
						}

						try stack.push(value)
					}
				case let .enum(enumType):
					guard let kase = enumType.cases[symbol] else {
						return runtimeError("enum \(enumType.name) has no member \(symbol)")
					}

					try stack.push(.enumCase(kase))
				case let .enumCase(enumCase):
					if propertyOptions.contains(.isMethod) {
						let boundMethod = Value.boundEnumMethod(enumCase, symbol)
						try stack.push(boundMethod)
					} else {
						return runtimeError("enums don't have properties")
					}
				default:
					return runtimeError("Receiver is not an instance of a struct or enum")
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

				// TODO: Make this user-implementable
				guard let getSlot = module.chunks.first(where: {
					$0.key.description.contains("\(receiver.type.name)$get$")
				}) else {
					throw VirtualMachineError.valueMissing("No get method for receiver: \(receiver)")
				}

				try call(
					boundMethod: getSlot.key,
					on: receiver
				)
			case .initArray:
				let count = try readByte()

				// We need to set the capacity to at least 1 or else trying to resize it will multiply 0 by 2
				// which means we never actually get more capacity.
				let capacity = max(count, 1)

				guard let arrayType = module.structs[.struct("Standard", "Array")] else {
					throw VirtualMachineError.valueMissing("No Array type found")
				}

				let pointer = heap.allocate(count: Int(capacity))
				for i in 0 ..< count {
					try heap.store(pointer: pointer + Int(i), value: stack.pop())
				}

				let instance = Instance(type: arrayType, fields: [
					.property("Standard", "Array", "_storage"): .pointer(pointer),
					.property("Standard", "Array", "count"): .int(.init(count)),
					.property("Standard", "Array", "capacity"): .int(.init(capacity)),
				])

				try stack.push(.instance(instance))
			case .initDict:
				guard let dictType = module.structs[.struct("Standard", "Dictionary")] else {
					throw VirtualMachineError.valueMissing("No Dictionary type found")
				}

				try call(structValue: dictType)
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
				let inlineFrame = try frames.pop()
				guard inlineFrame.isInline else {
					return runtimeError("Frame not inline!")
				}
				ip = inlineFrame.returnTo
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
			}
		}
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

	// Call a method on a struct instance.
	// Takes the method offset, instance and type that defines the method.
	private mutating func call(boundMethod: Symbol, on instance: Instance) throws {
		var boundMethod = boundMethod

		if case let .method(nil, name, params) = boundMethod.kind {
			boundMethod = .init(module: boundMethod.module, kind: .method(instance.type.name, name, params))
		}

		guard let methodChunk = module.chunks[boundMethod] else {
			throw VirtualMachineError.valueMissing("no method found \(boundMethod)")
		}

		try call(chunk: methodChunk, withSelf: .instance(instance), additionalOffset: 1)
	}

	// Call a method on a struct instance.
	// Takes the method offset, instance and type that defines the method.
	private mutating func call(boundMethod: Symbol, on enumCase: EnumCase) throws {
		var boundMethod = boundMethod

		if case let .method(nil, name, params) = boundMethod.kind {
			boundMethod = .init(module: boundMethod.module, kind: .method(enumCase.type, name, params))
		}

		guard let methodChunk = module.chunks[boundMethod] else {
			throw VirtualMachineError.valueMissing("no method found \(boundMethod)")
		}

		try call(chunk: methodChunk, withSelf: .enumCase(enumCase))
	}

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

		try frames.push(frame)
	}

	private mutating func call(closureID: Symbol) throws {
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

		try frames.push(frame)
	}

	private mutating func call(chunkID: Symbol, inline: Bool = false) throws {
		guard let chunk = module.chunks[chunkID] else {
			throw VirtualMachineError.valueMissing("No chunk found for symbol: \(chunkID)")
		}

		let capturing: [Symbol: Capture.Location] = chunk.capturing.reduce(into: [:]) { res, capture in
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

		try frames.push(frame)
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

	private mutating func call(builtin: Symbol) throws {
		switch builtin.kind {
		case .function("print", _):
			let value = try stack.pop()
			let string = inspect(value) + "\n"
			try output.write([Byte](Data(string.utf8)), to: .stdout)
		case .function("_allocate", _):
			if case let .int(count) = try stack.pop() { // Get the capacity
				let pointer = heap.allocate(count: Int(count))
				try stack.push(.pointer(pointer))
			}
		case .function("_deref", _):
			guard case let .pointer(pointer) = try stack.pop() else {
				throw VirtualMachineError.typeError("cannot dereference non-pointer")
			}

			guard let value = heap.dereference(pointer: pointer) else {
				throw VirtualMachineError.valueMissing("no value found for pointer \(pointer)")
			}

			try stack.push(value)
		case .function("_free", _):
			try stack.pop()
			() // TODO:
		case .function("_storePtr", _):
			let value = try stack.pop()
			let pointer = try stack.pop()
			if case let .pointer(pointer) = pointer {
				heap.store(pointer: pointer, value: value)
			} else {
				throw VirtualMachineError.typeError("expected pointer, got \(pointer)")
			}
		case .function("_hash", _):
			let value = try stack.pop()
			try stack.push(.int(.init(value.hashValue)))
		case .function("_cast", _):
			() // This is just for the analyzer
		default:
			throw VirtualMachineError.valueMissing("unknown builtin: \(builtin)")
		}
	}

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
				closures[sym]?.capturing[local] = .heap(pointer)
			}
		}
	}

	private mutating func readConstant() throws -> Value {
		let value = try chunk.constants[Int(readByte())]
		return value
	}

	private mutating func readByte() throws -> Byte {
		defer { ip += 1 }
		return try chunk.code[Int(ip)].asByte()
	}

	private mutating func readOpcode() throws -> Opcode {
		defer { ip += 1 }
		return try chunk.code[Int(ip)].asOpcode()
	}

	private mutating func readCapture() throws -> Capture {
		defer { ip += 1 }
		return try chunk.code[Int(ip)].asCapture()
	}

	private mutating func readSymbol() throws -> Symbol {
		defer { ip += 1 }
		return try chunk.code[Int(ip)].asSymbol()
	}

	private mutating func readUInt16() throws -> UInt64 {
		var jump = try UInt64(readByte() << 8)
		jump |= try UInt64(readByte())
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
		FileHandle.standardError.write(Data((string + "\n").utf8))
	}
}
