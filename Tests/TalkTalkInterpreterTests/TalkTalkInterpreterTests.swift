import Testing
@testable import TalkTalkInterpreter

class TestOutput: Output {
	func print(_ output: Any...) {
		out += output.map { "\($0)"}.joined(separator: "") + "\n"
	}

	func print(_ output: Any..., terminator: String) {
		out += output.map { "\($0) "}.joined(separator: ", ") + terminator
	}

	var out = ""
}

@Test(
	"Inputs and outputs",
	arguments: [
		(
			"""
			print "hello world";
			""",
			"""
			string("hello world")

			"""
		),
		(
			"""
			print 1 + 1;
			""",
			"""
			number(2.0)

			"""
		),
		(
			"""
			class Person {
				init(name) {
					self.name = name;
				}

				func greet() {
					print "hello, " + self.name;
				}
			}

			Person("pat").greet();
			""",
			"""
			string("hello, pat")

			"""
		),
	]
) func helloWorld(input: String, output: String) throws {
	let actual = TestOutput()
	var interpreter = TalkTalkInterpreter(input: input, tokenize: false, output: actual)
	try interpreter.run()

	#expect(actual.out == output)
}
