//
//  VM.swift
//
//
//  Created by Pat Nakajima on 6/30/24.
//

public enum InterpretResult {
	case ok,
	     compileError,
	     runtimeError
}

public class VM<Output: OutputCollector> {
	var output: Output
	var stack = Stack<Value>()
	var frames = Stack<CallFrame>()
	var globals: [String: Value] = [:]

	static func run(source: String, output: Output) -> InterpretResult {
		let vm = VM(output: output)
		let compiler = Compiler(source: source)

		do {
			try compiler.compile()
		} catch {
			output.print(compiler.errors.map { $0.description }.joined(separator: "\n"))
			return .compileError
		}

		return vm.run(function: compiler.currentFunction)
	}

	public init(output: Output = StdoutOutput()) {
		self.output = output
		for (name, function) in Native.list {
			globals[name] = .native(function.init().name)
		}
	}

	func initVM() {
		stack.reset()
	}

	func stackDebug() {
		if stack.isEmpty { return }
		output.debug("\t\t\t\t\t\tStack (\(stack.size): ", terminator: "")
		for slot in 0 ..< stack.size {
			output.debug("[\(stack.peek(offset: stack.size - slot - 1).description)]", terminator: "")
		}
		output.debug()
	}

	public func run(source: String) -> InterpretResult {
		let compiler = Compiler(source: source)

		do {
			try compiler.compile()
		} catch {
			return .compileError
		}

		return run(function: compiler.currentFunction)
	}

	public func run(function root: Function) -> InterpretResult {
		stack.push(.function(root))
		let rootClosure = Closure(function: root)
		_ = call(rootClosure, argCount: 0)

//		output.debug(Disassembler.header)
//		Disassembler.dump(chunk: chunk, into: StdoutOutput())

		while true {
			#if DEBUGGING
				stackDebug()
				Disassembler.dump(chunk: chunk, ip: ip, into: output)
//			disassembler.report(ip: ip)

			#endif

			let byte = readByte()
			guard let opcode = Opcode(rawValue: byte) else {
				print("Unknown opcode: \(byte)")
				return .runtimeError
			}

			switch opcode {
			case .return:
				let result = stack.pop()
				let frame = frames.pop()

				if frames.isEmpty {
					return .ok
				}

				// Discard slots that were used for passing arguments and params
				// and locals
				for _ in 0 ..< frame.offset {
					let _ = stack.pop()
				}

				// Append the return value
				stack.push(result)
			case .negate:
				stack.push(-stack.pop())
			case .constant:
				stack.push(readConstant())
			case .add:
				let b = stack.pop()
				let a = stack.pop()
				stack.push(a + b)
			case .subtract:
				let b = stack.pop()
				let a = stack.pop()
				stack.push(a - b)
			case .multiply:
				let b = stack.pop()
				let a = stack.pop()
				stack.push(a * b)
			case .divide:
				let b = stack.pop()
				let a = stack.pop()
				stack.push(a / b)
			case .less:
				let b = stack.pop()
				let a = stack.pop()
				stack.push(a < b)
			case .greater:
				let b = stack.pop()
				let a = stack.pop()
				stack.push(a > b)
			case .nil:
				stack.push(.nil)
			case .true:
				stack.push(.bool(true))
			case .false:
				stack.push(.bool(false))
			case .not:
				stack.push(stack.pop().not())
			case .equal:
				let a = stack.pop()
				let b = stack.pop()
				stack.push(.bool(a == b))
			case .notEqual:
				let a = stack.pop()
				let b = stack.pop()
				stack.push(.bool(a != b))
			case .pop:
				_ = stack.pop()
			case .print:
				output.print(stack.pop().description)
			case .defineGlobal:
				let name = readString()
				globals[name] = peek()
				_ = stack.pop()
			case .getGlobal:
				let name = readString()
				guard let value = globals[name] else {
					output.debug("Undefined variable '\(name)' \(globals.debugDescription)")
					output.print("Error: Undefined variable '\(name)'")
					return .runtimeError
				}
				stack.push(value)
			case .setGlobal:
				let name = readString()
				if globals[name] == nil {
					runtimeError("Undefined variable \(name).")
					return .runtimeError
				}

				globals[name] = peek()
			case .getLocal:
				let slot = readByte()
				stack.push(
					currentFrame.stack[Int(slot)]
				)
			case .setLocal:
				let slot = readByte()
				currentFrame.stack[Int(slot)] = peek()
			case .uninitialized:
				runtimeError("Unitialized instruction cannot be run: \(peek().description)")
			case .jump:
				let offset = readShort()
				currentFrame.ip += Int(offset)
			case .jumpIfFalse:
				let offset = readShort()
				let isTrue = peek().as(Bool.self)
				if !isTrue {
					currentFrame.ip += Int(offset)
				}
			case .loop:
				let offset = readShort()
				currentFrame.ip -= Int(offset)
			case .call:
				let argCount = readByte()
				if !callValue(peek(argCount), argCount) {
					return .runtimeError
				}
			case .closure:
				let function = readConstant().as(Function.self)
				let closure = Closure(function: function)

				for i in 0 ..< closure.function.upvalueCount {
					let isLocal = readByte() == 1
					let index = Int(readByte())
					if isLocal {
						closure.upvalues[i] = captureUpvalue(currentFrame.stack[index])
					} else {
						closure.upvalues[i] = currentFrame.closure.upvalues[index]
					}
				}

				stack.push(.closure(closure))
			case .getUpvalue:
				let slot = readByte()
				stack.push(currentFrame.closure.upvalues[Int(slot-1)]!)
			case .setUpvalue:
				let slot = readByte()
				currentFrame.closure.upvalues[Int(slot)] = peek(0)
			}
		}
	}

	func captureUpvalue(_ local: Value) -> Value {
		return .upvalue(local)
	}

	func callValue(_ callee: Value, _ argCount: Byte) -> Bool {
		switch callee {
		case let .closure(closure):
			return call(closure, argCount: argCount)
		case let .native(name):
			if let fn = Native.list[name]?.init() {
				let args = stack.pop(count: fn.arity)
				stack.push(fn.call(arguments: args, in: NativeEnvironment(output: output)))
				return true
			} else {
				runtimeError("No native function named \(name)")
				return false
			}
		default:
			runtimeError("\(callee) not callable")
			return false // Non-callable type
		}
	}

	func call(_ closure: Closure, argCount: Byte) -> Bool {
		let fn = closure.function
		if argCount != fn.arity {
			runtimeError("Expected \(fn.arity) arguments for \(fn.name)(), got \(argCount)")
			return false
		}

		if frames.size > 255 {
			runtimeError("Stack level too deep")
			return false
		}

		let frame = CallFrame(closure: closure, stack: stack, offset: stack.size - Int(argCount) - 1)
		frames.push(frame)
		return true
	}

	func readShort() -> UInt16 {
		// Move two bytes, because we're gonna read... two bytes
		ip += 2

		let a = chunk.code[ip - 2]
		let b = chunk.code[ip - 1]

		// Grab those two bytes from the chunk's code and build
		// a 16 bit (two byte, nice) unsigned int.
		return UInt16((a << 8) | b)
	}

	func readString() -> String {
		return chunk.constants.read(byte: readByte()).as(String.self)
	}

	func readConstant() -> Value {
		chunk.constants[Int(readByte())]
	}

	func readByte() -> Byte {
		defer {
			ip += 1
		}

		return chunk.code[ip]
	}

	func peek(_ offset: Byte) -> Value {
		stack.peek(offset: Int(offset))
	}

	func peek(_ offset: Int = 0) -> Value {
		stack.peek(offset: offset)
	}

	func runtimeError(_ message: String) {
		output.print("------------------------------------------------------------------")
		output.print("Runtime Error: \(message)")
		output.print("------------------------------------------------------------------")
		stackDebug()
		var i = frames.size - 1
		while i >= 0 {
			let frame = frames[i]
			let function = frame.closure.function
			let instruction = function.chunk.code[ip - 1]
			output.print("\t[line \(function.chunk.lines[Int(instruction)])] in \(function.name)()")
			i -= 1
		}

		stack.reset()
	}

	var chunk: Chunk {
		currentFrame.closure.function.chunk
	}

	var ip: Int {
		get {
			currentFrame.ip
		}

		set {
			currentFrame.ip = newValue
		}
	}

	var currentFrame: CallFrame {
		frames.peek()
	}
}
