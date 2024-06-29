import Testing
@testable import tlk

@Suite("TalkTalk") struct TalkTalkTests {
	@Test func environmentTests() throws {
		let parent = Environment()
		let environment = Environment(parent: parent)

		// Test assigning to outer scope
		parent.initialize(name: "foo", value: .string("bar"))
		_ = try environment.assign(name: "foo", value: .string("baz"))
		#expect(parent.lookup(name: "foo") == .string("baz"))
		#expect(environment.lookup(name: "foo") == .string("baz"))

		// Test inner declaration doesn't go to outer
		environment.initialize(name: "fizz", value: .string("buzz"))
		#expect(environment.lookup(name: "fizz") == .string("buzz"))
		#expect(parent.lookup(name: "fizz") == nil)
	}
}
