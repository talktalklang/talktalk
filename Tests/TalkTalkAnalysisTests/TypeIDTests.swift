//
//  TypeIDTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/23/24.
//

import Testing
import TalkTalkSyntax
import TalkTalkAnalysis

struct TypeIDTests {
	@Test("Can be created") func basic() {
		#expect(TypeID(.placeholder).current == .placeholder)
	}

	@Test("Can be inferred from") func inferFrom() {
		let source = TypeID(.placeholder)
		let child = TypeID(.placeholder)

		// The child is inferring its type from the source
		child.infer(from: source)

		// The source gets its type updated
		_ = source.update(.int, location: [.synthetic(.identifier)])

		#expect(child.current == .int)
	}

	@Test("Can update its inferredFrom") func inferTo() {
		let source = TypeID(.placeholder)
		let child = TypeID(.placeholder)
		child.infer(from: source)
		let childB = TypeID(.placeholder)
		childB.infer(from: source)

		// The child gets updated type information
		_ = child.update(.int, location: [.synthetic(.identifier)])

		// The source gets its type updated
		#expect(source.current == .int)

		// The source's other child gets its type updated
		#expect(childB.current == .int)
	}
}
