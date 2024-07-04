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

struct Stack: ~Copyable {
	var count = 0
	private var storage: [Value] = []

	subscript(_ offset: Int) -> Value {
		get {
			storage[offset]
		}

		set {
			storage[offset] = newValue
		}
	}

	var isEmpty: Bool {
		count == 0
	}

	func peek(offset: Int = 0) -> Value {
		storage[count - 1 - offset]
	}

	mutating func push(_ value: Value) {
		storage.append(value)
		count += 1
	}

	mutating func pop() -> Value {
		count -= 1
		return storage.removeLast()
	}

	mutating func reset() {
		count = 0
		storage = []
	}
}

public struct VM<Output: OutputCollector>: ~Copyable {
	var output: Output
	var ip: Int = 0
	var stack = Stack()
	var globals: [String: Value] = [:]

	static func run(source: String, output: Output) -> InterpretResult {
		var vm = VM(output: output)
		var compiler = Compiler(source: source)

		do {
			try compiler.compile()
		} catch {
			for error in compiler.errors {
				output.print(error.description)
			}

			return .compileError
		}

		return vm.run(chunk: &compiler.compilingChunk)
	}

	public init(output: Output = StdoutOutput()) {
		self.output = output
	}

	mutating func initVM() {
		stack.reset()
	}

	var stackSize: Int {
		stack.count
	}

	mutating func stackPush(_ value: Value) {
		stack.push(value)
	}

	mutating func stackPop() -> Value {
		stack.pop()
	}

	mutating func stackDebug() {
		if stack.isEmpty { return }
		output.debug("\t\t\t\t\t\tStack (\(stackSize): ", terminator: "")
		for slot in 0..<stack.count {
			output.debug("[\(stack.peek(offset: slot).description)]", terminator: "")
		}
		output.debug()
	}

	public mutating func run(source: String) -> InterpretResult {
		var compiler = Compiler(source: source)
		do {
			try compiler.compile()
		} catch {
			return .compileError
		}

		var chunk = compiler.compilingChunk
		return run(chunk: &chunk)
	}

	public mutating func run(chunk: inout Chunk) -> InterpretResult {
		ip = 0

		#if DEBUGGING
			output.debug(Disassembler<Output>.header)
		#endif

		while true {
			#if DEBUGGING
				var disassembler = Disassembler(output: output)
				disassembler.report(byte: ip, in: chunk)
				stackDebug()
			#endif

			let byte = readByte(in: chunk)
			guard let opcode = Opcode(rawValue: byte) else {
				print("Unknown opcode: \(byte)")
				return .runtimeError
			}

			switch opcode {
			case .return:
				if stackSize != 0 {
					output.print("Warning: Stack left at \(stackSize)")
				}

				return .ok
			case .negate:
				stackPush(-stackPop())
			case .constant:
				stackPush(readConstant(in: chunk))
			case .add:
				let b = stackPop()
				let a = stackPop()
				stackPush(a + b)
			case .subtract:
				let b = stackPop()
				let a = stackPop()
				stackPush(a - b)
			case .multiply:
				let b = stackPop()
				let a = stackPop()
				stackPush(a * b)
			case .divide:
				let b = stackPop()
				let a = stackPop()
				stackPush(a / b)
			case .less:
				let b = stackPop()
				let a = stackPop()
				stackPush(a < b)
			case .greater:
				let b = stackPop()
				let a = stackPop()
				stackPush(a > b)
			case .nil:
				stackPush(.nil)
			case .true:
				stackPush(.bool(true))
			case .false:
				stackPush(.bool(false))
			case .not:
				stackPush(stackPop().not())
			case .equal:
				let a = stackPop()
				let b = stackPop()
				stackPush(.bool(a == b))
			case .notEqual:
				let a = stackPop()
				let b = stackPop()
				stackPush(.bool(a != b))
			case .pop:
				_ = stackPop()
			case .print:
				output.print(stackPop().description)
			case .defineGlobal:
				let name = chunk.constants.read(byte: readByte(in: chunk)).as(String.self)
				globals[name] = peek()
				_ = stackPop()
			case .getGlobal:
				let name = readString(in: chunk)
				guard let value = globals[name] else {
					output.debug("Undefined variable '\(name)' \(globals.debugDescription)")
					output.print("Error: Undefined variable '\(name)'")
					return .runtimeError
				}
				stackPush(value)
			case .setGlobal:
				let name = chunk.constants.read(byte: readByte(in: chunk)).as(String.self)
				if globals[name] == nil {
					runtimeError("Undefined variable \(name).")
					return .runtimeError
				}

				globals[name] = peek()
			case .getLocal:
				let slot = readByte(in: chunk)
				stackPush(stack[Int(slot)])
			case .setLocal:
				let slot = readByte(in: chunk)
				stack[Int(slot)] = peek()
			case .uninitialized:
				runtimeError("Unitialized instruction cannot be run: \(peek().description)")
			case .jump:
				let offset = readShort(in: chunk)
				ip += Int(offset)
			case .jumpIfFalse:
				let offset = readShort(in: chunk)
				let isTrue = peek().as(Bool.self)
				if !isTrue {
					ip += Int(offset)
				}
			case .loop:
				let offset = readShort(in: chunk)
				ip -= Int(offset)
			}
		}
	}

	mutating func readShort(in chunk: borrowing Chunk) -> UInt16 {
		// Move two bytes, because we're gonna read... two bytes
		ip += 2

		let a = chunk.code[ip - 2]
		let b = chunk.code[ip - 1]

		// Grab those two bytes from the chunk's code and build
		// a 16 bit (two byte, nice) unsigned int.
		return UInt16((a << 8) | b)
	}

	mutating func readString(in chunk: borrowing Chunk) -> String {
		return chunk.constants.read(byte: readByte(in: chunk)).as(String.self)
	}

	mutating func readConstant(in chunk: borrowing Chunk) -> Value {
		chunk.constants[Int(readByte(in: chunk))]
	}

	mutating func readByte(in chunk: borrowing Chunk) -> Byte {
		defer {
			ip += 1
		}

		return chunk.code[ip]
	}

	func peek(_ offset: Int = 0) -> Value {
		stack.peek(offset: offset)
	}

	func runtimeError(_ message: String) {
		output.print("Runtime Error: \(message)")
	}
}
