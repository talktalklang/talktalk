#if canImport(Glibc)
import Glibc
func now() -> Double { Double(time(nil)) }
#elseif canImport(Foundation)
import Foundation
func now() -> Double { Double(Date().timeIntervalSince1970) }
#else
func now() { fatalError("No way to tell time. Interesting gambit.") }
#endif

struct ClockCallable: Callable {
	func call(_ context: inout AstInterpreter, arguments: [Value]) -> Value {
		.number(now())
	}
}

extension AstInterpreter {
	mutating func defineClock() {
		globals.define(name: "clock", callable: ClockCallable())
	}
}
