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

public protocol OutputCollector: AnyObject {
	func print(_ output: String, terminator: String)
	func debug(_ output: String, terminator: String)
}

public final class StdoutOutput: OutputCollector {
	public func print(_ output: String, terminator: String) {
		Swift.print(output, terminator: terminator)
	}

	public func debug(_ output: String, terminator: String) {
		Swift.print(output, terminator: terminator)
	}

	public init() {}
}

public extension OutputCollector {
	func print() {
		self.print("")
	}

	func debug() {
		self.debug("", terminator: "\n")
	}

	func debug(_ output: String) {
		self.debug(output, terminator: "\n")
	}

	func print(_ output: String) {
		self.print(output, terminator: "\n")
	}

	func printf(_ string: String, _ args: CVarArg...) {
		self.print(String(format: string, args), terminator: "")
	}

	func print(format string: String, _ args: CVarArg...) {
		self.print(String(format: string, args))
	}
}

public struct VM<Output: OutputCollector>: ~Copyable {
	var output: Output
	var ip: UnsafeMutablePointer<Byte>?
	var stack: UnsafeMutablePointer<Value>
	var stackTop: UnsafeMutablePointer<Value>

	public init(output: Output = StdoutOutput()) {
		self.output = output
		self.stack = UnsafeMutablePointer<Value>.allocate(capacity: 256)
		self.stack.initialize(repeating: .nil, count: 256)
		self.stackTop = UnsafeMutablePointer<Value>(stack)
		self.stackTop.initialize(repeating: .nil, count: 256)
	}

	mutating func initVM() {
		stackReset()
	}

	mutating func stackReset() {
		stackTop = UnsafeMutablePointer<Value>(stack)
	}

	mutating func stackPush(_ value: Value) {
		if stackTop - stack >= 256 {
			fatalError("Stack level too deep.") // TODO: Just grow the stack babyyyyy
		}

		stackTop.pointee = value
		stackTop += 1
	}

	mutating func stackPop() -> Value {
		stackTop -= 1
		return stackTop.pointee
	}

	mutating func stackDebug() {
		if stack == stackTop { return }
		output.debug("\t\t\t\tStack: ", terminator: "")
		if stack < stackTop {
			for slot in stack..<stackTop {
				output.debug("[\(slot.pointee)]", terminator: "")
			}
		} else {
			output.print("Stack is in invalid state.")
		}
		output.debug()
	}

	public mutating func run(source: String) -> InterpretResult {
		var compiler = Compiler(source: source)
		compiler.compile()

		var chunk = compiler.compilingChunk

		return run(chunk: &chunk)
	}

	public mutating func run(chunk: inout Chunk) -> InterpretResult {
		self.ip = chunk.code.storage

		while true {
			#if DEBUGGING
			var disassembler = Disassembler(output: output)
			disassembler.report(byte: ip!, in: chunk)
			stackDebug()
			#endif

			let opcode = Opcode(rawValue: readByte())

			switch opcode {
			case .return:
				output.print(stackPop().description, terminator: "")
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
			default:
				print("Unknown opcode: \(opcode?.description ?? "nil")")
				return .runtimeError
			}
		}
	}

	mutating func readConstant(in chunk: borrowing Chunk) -> Value {
		(chunk.constants.storage + UnsafeMutablePointer<Value>.Stride(readByte())).pointee
	}

	mutating func readByte() -> Byte {
		guard let ip else {
			return .min
		}

		defer {
			self.ip = ip.successor()
		}

		return ip.pointee
	}

	deinit {
		// I don't think I have to deallocate stackTop since it only
		// refers to memory contained in stack? Same with ip?
		stack.deallocate()
	}
}
