@testable import swlox
import XCTest

class SwloxTests: XCTestCase {
	func testEnvironment() throws {
		let parent = Environment()
		let environment = Environment(parent: parent)

		// Test assigning to outer scope
		parent.initialize(name: "foo", value: .string("bar"))
		_ = try environment.assign(name: "foo", value: .string("baz"))
		XCTAssertEqual(parent.lookup(name: "foo"), .string("baz"))
		XCTAssertEqual(environment.lookup(name: "foo"), .string("baz"))

		// Test inner declaration doesn't go to outer
		environment.initialize(name: "fizz", value: .string("buzz"))
		XCTAssertEqual(environment.lookup(name: "fizz"), .string("buzz"))
		XCTAssertNil(parent.lookup(name: "fizz"))
	}
}
