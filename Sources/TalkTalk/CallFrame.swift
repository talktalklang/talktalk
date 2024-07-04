//
//  CallFrame.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
class CallFrame {
	let function: Function
	let stack: CallFrameStack
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
				stackRef[slot - 1 + offset]
			}

			set {
				stackRef[slot - 1 + offset] = newValue
			}
		}
	}

	init(function: Function, stack: Stack<Value>, offset: Int) {
		self.function = function
		self.stack = CallFrameStack(stackRef: stack, offset: offset)
		self.offset = offset
	}
}
