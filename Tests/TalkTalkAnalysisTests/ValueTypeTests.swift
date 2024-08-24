//
//  ValueTypeTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/24/24.
//

import Testing
import TalkTalkAnalysis

struct ValueTypeTests {
	@Test("int is assignable to int") func intAssign() {
		#expect(ValueType.int.isAssignable(from: .int))
		#expect(!ValueType.int.isAssignable(from: .bool))
	}

	@Test("Generics with matching bound types are assignable") func genericsWithMatchingTypes() {
		let a = ValueType.instance(.struct("Wrapper", ["Wrapped": TypeID(.int)]))
		let b = ValueType.instance(.struct("Wrapper", ["Wrapped": TypeID(.int)]))
		#expect(a.isAssignable(from: b))
	}

	@Test("Generics with one that's a placeholder are assignable") func genericsWithPlaceholder() {
		let a = ValueType.instance(.struct("Wrapper", ["Wrapped": TypeID(.placeholder)]))
		let b = ValueType.instance(.struct("Wrapper", ["Wrapped": TypeID(.int)]))
		#expect(a.isAssignable(from: b))
	}
}
