@testable import TalkTalkInterpreter
import Testing

class TestOutput: Output {
	var debug: Bool = false

	func print(_ output: Any...) {
		if debug {
			Swift.print(output)
		}
		out += output.map { "\($0)" }.joined(separator: "") + "\n"
	}

	func print(_ output: Any..., terminator: String) {
		out += output.map { "\($0) " }.joined(separator: ", ") + terminator
	}

	var out = ""

	init(debug: Bool = false, out: String = "") {
		self.debug = debug
		self.out = out
	}
}

@Test("Bench") func bench() throws {
	let source = """
	func fib(n) {
		if (n <= 1) { return n; }
		return fib(n - 2) + fib(n - 1);
	}

	var i = 0;
		while i < 25 {
		print fib(i);
		i = i + 1;
	}
	"""

	var interpreter = TalkTalkInterpreter(
		input: source,
		tokenize: false,
		output: TestOutput(debug: true)
	)

	try interpreter.run()
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
