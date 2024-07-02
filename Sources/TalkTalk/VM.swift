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
	func print(_ output: String)
	func print(_ output: String, terminator: String)
}

public final class StdoutOutput: OutputCollector {
	public func print(_ output: String) {
		Swift.print(output)
	}

	public func print(_ output: String, terminator: String) {
		Swift.print(output, terminator: terminator)
	}

	public init() {}
}

public extension OutputCollector {
	func print() {
		self.print("")
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
		output.print("\t\t\t\tStack: ", terminator: "")
		for slot in stack..<stackTop {
			output.print("[\(slot.pointee)]", terminator: "")
		}
		output.print()
	}

	public mutating func run(chunk: inout Chunk) -> InterpretResult {
		self.ip = chunk.code.storage

		while true {
			#if DEBUGGING
			var disassembler = Disassembler(output: output)
			disassembler.report(byte: ip!, in: chunk)
			stackDebug()
			#endif

			switch Opcode(rawValue: readByte()) {
			case .return:
				output.print("\t\t\t\t\(stackPop())")
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
			default:
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
