//
//  CallFrameTests.swift
//
//
//  Created by Pat Nakajima on 7/6/24.
//
@testable import TalkTalk
import Testing

struct CallFrameTests {
	@Test("Stack window") func frame() {
		var stack = Stack<Value>(capacity: 16)
		for i in 0 ..< 10 {
			stack.push(.int(Int(i)))
		}

		#expect(stack.size == 10)
		#expect(stack.peek() == .int(9))

		let closure = Closure(function: Function(arity: 3, chunk: Chunk(), name: "testin"))

		let callFrame = CallFrame(
			closure: closure,
			stack: stack,
			stackOffset: 3
		)

		#expect(callFrame.stack[0] == .int(3))
	}
}
