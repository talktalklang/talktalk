//
//  CallFrame.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
class CallFrame {
	let closure: Closure
	let stack: CallFrameStack
	let originalStackLocation: Int
	let offset: Int
	var ip: Int = 0

	class CallFrameStack {
		var stackRef: Stack<Value>
		let offset: Int

		init(stackRef: Stack<Value>, offset: Int) {
			self.stackRef = stackRef
			self.offset = offset
		}

		subscript(_ slot: Int) -> Value {
			get {
				stackRef[slot + offset]
			}

			set {
				stackRef[slot + offset] = newValue
			}
		}
	}

	init(closure: Closure, stack: Stack<Value>, offset: Int) {
		self.closure = closure
		self.stack = CallFrameStack(stackRef: stack, offset: offset)
		self.originalStackLocation = stack.size
		self.offset = offset
	}
}
