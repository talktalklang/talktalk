//
//  StackTests.swift
//  
//
//  Created by Pat Nakajima on 7/5/24.
//
@testable import TalkTalk
import Testing

struct StackTests {
	@Test("peek()") func peek() {
		let stack = Stack<Int>()
		stack.push(3)
		stack.push(2)
		stack.push(1)
		#expect(1 == stack.peek())
	}
}
