//
//  CallFrame.swift
//
//
//  Created by Pat Nakajima on 7/3/24.
//
struct CallFrame {
	var closure: Closure
	var stack: CallFrameStack
	let stackOffset: Int
	var lastIP: Int = 0

	struct CallFrameStack {
		var stackRef: Stack<Value>
		let offset: Int

		init(stackRef: Stack<Value>, offset: Int) {
			self.stackRef = stackRef
			self.offset = offset
		}

		subscript(_ slot: Int) -> Value {
			get {
				stackRef[offset + slot]
			}

			set {
				stackRef[offset + slot] = newValue
			}
		}
	}

	init(closure: Closure, stack: Stack<Value>, stackOffset: Int) {
		self.closure = closure
		self.stack = CallFrameStack(stackRef: stack, offset: stackOffset)
		self.stackOffset = stackOffset
	}
}
