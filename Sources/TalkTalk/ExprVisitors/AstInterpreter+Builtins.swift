import Glibc

struct ClockCallable: Callable {
	func call(_ context: inout AstInterpreter, arguments: [Value]) -> Value {
		.number(Double(time(nil)))
	}
}

extension AstInterpreter {
	mutating func defineClock() {
		globals.define(name: "clock", callable: ClockCallable())
	}
}
