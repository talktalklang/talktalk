//
//  PatternMatchTests.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/10/24.
//

import Testing

struct PatternMatchTests: VMTest {
	@Test("Basic") func basic() throws {
		let result = try run(
			"""
			match true {
			case false:
				return 123
			case true:
				return 456
			}
			"""
		)

		#expect(result == .int(456))
	}

	@Test("Basic with else") func basicElse() throws {
		let result = try run(
			"""
			match true {
			case false:
				return 123
			else:
				return 456
			}
			"""
		)

		#expect(result == .int(456))
	}

	@Test("else doesn't always win") func basicElse2() throws {
		let result = try run(
			"""
			match true {
			case true:
				return 123
			else:
				return 456
			}
			"""
		)

		#expect(result == .int(123))
	}

	@Test("With binding") func withBinding() throws {
		let result = try run(
			"""
			enum Thing {
			case foo(int)
			case bar(int)
			}

			match Thing.bar(456) {
			case .foo(let a):
				return a
			case .bar(let b):
				return b + 1
			}
			"""
		)

		#expect(result == .int(457))
	}

	@Test("With values") func withValues() throws {
		let result = try run(
			"""
			enum Thing {
			case foo(int)
			case bar(int)
			}

			match Thing.foo(456) {
			case .foo(123):
				return "nope 123"
			case .bar(let a):
				return "nope bar"
			case .foo(456):
				return "yup"
			}
			"""
		)

		#expect(result == .string("yup"))
	}

	@Test("With generics") func withGenerics() throws {
		let result = try run(
			"""
			enum Thing<Wrapped> {
			case foo(Wrapped)
			}

			match Thing.foo(789) {
			case .foo(let wrapped):
				return wrapped
			}
			"""
		)

		#expect(result == .int(789))
	}

	@Test("Matching variable") func matchingVariable() throws {
		let result = try run(
			"""
			enum Thing {
			case foo(int)
			case bar(int)
			}

			let variable = Thing.foo(456) 

			match variable {
			case .foo(123):
				return "nope 123"
			case .bar(let a):
				return "nope bar"
			case .foo(456):
				return "yup"
			}
			"""
		)

		#expect(result == .string("yup"))
	}

	@Test("Matching nested patterns") func matchingNestedPatterns() throws {
		let source = """
		enum A {
			case foo(int, B)
			case bar(int, B)
		}

		enum B {
			case fizz(int)
			case buzz(int)
		}

		let variable = A.foo(10, .fizz(20)) 

		match variable {
		case .bar(let a, .fizz(let b)):
			return 29 // Nope
		case .foo(let a, .fizz(let b)):
			return a + b
		}
		"""

		let result = try run(source)

		#expect(result == .int(30))
	}

	@Test("Runs bodies") func runsBodies() throws {
		let source = """
		enum Foo {
			case fizz(int)
			case buzz(String)
		}

		let fooA = Foo.fizz(123)

		print("let's go")

		match fooA {
		case .fizz(let int):
			print("Got the int")
		case .buzz(let string):
			print("Got the string")
		}

		let fooB = Foo.buzz("sup")

		match fooB {
		case .fizz(let int):
			print("Got the int")
		case .buzz(let string):
			print("Got the string")
		}
		"""

		let output = TestOutput()

		_ = try run(source, output: output)

		#expect(output.stdout == """
		let's go
		Got the int
		Got the string

		""")
	}

	@Test("Doesn't leak variables out of bodies") func doesntLeak() throws {
		let result = try run(
			"""
			enum Thing {
			case foo(int)
			}

			var a = 123

			match Thing.foo(456) {
			case .foo(let a):
				a + 1
			}

			return a + 2
			"""
		)

		#expect(result == .int(125))
	}

	@Test("Doesn't prevent returns") func canReturn() throws {
		let result = try run(
			"""
			return func() {
				match true {
				case true:
					return "good"
				case false:
					return "whatever"
				}

				return "bad"
			}()
			"""
		)

		#expect(result == .string("good"))
	}

	@Test("Enum methods") func enumMethods() throws {
		let resulta = try run(
			"""
			enum Thing {
				case foo
				case bar

				func isFoo() {
					self == .foo
				}
			}

			return Thing.foo.isFoo()
			"""
		)

		#expect(resulta == .bool(true))

		let resultb = try run(
			"""
			enum Thing {
				case foo
				case bar

				func isFoo() {
					self == .bar
				}
			}

			return Thing.foo.isFoo()
			"""
		)

		#expect(resultb == .bool(false))
	}
}
