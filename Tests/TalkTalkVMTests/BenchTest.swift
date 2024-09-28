//
//  BenchTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/22/24.
//

import Testing

struct BenchTests: VMTest {
	@Test("Basic", .disabled()) func basic() throws {
		let code = #"""
		protocol Greetable {
			var name: String
		}

		protocol Greeter {
			func greet(name: String) -> String
		}

		struct Person: Greeter, Greetable {
			var name: String

			func greet(name: String) -> String {
				"Oh hi, \(name)"
			}
		}

		struct Animal: Greetable {
			var name: String
		}

		let count = 300

		var j = 0
			while j < count {
			// TODO: it's be nice to infer array types based on first use?
			var people = [Person("Pat")]
			var animals  = [Animal("Pooch")]

			var i = 0
			while i < count {
				i = i + 1
				people.append(Person(name: "Person \(i)"))
				animals.append(Animal(name: "Animal \(i)"))
			}

			i = 0
			while i < count {
				let person = people[i]
				let animal = animals[i]
				person.greet(name: animal.name)
				i = i + 1
			}

			print("all done with j \(j)")

			j += 1
		}

		"""#

		let output = TestOutput()
		_ = try run(code, output: output)
//
//		let expected = """
//		all done with j 0
//		all done with j 1
//		all done with j 2
//		all done with j 3
//		all done with j 4
//		all done with j 5
//		all done with j 6
//		all done with j 7
//		all done with j 8
//		all done with j 9
//		all done with j 10
//		all done with j 11
//		all done with j 12
//		all done with j 13
//		all done with j 14
//		all done with j 15
//		all done with j 16
//		all done with j 17
//		all done with j 18
//		all done with j 19
//		all done with j 20
//		all done with j 21
//		all done with j 22
//		all done with j 23
//		all done with j 24
//		all done with j 25
//		all done with j 26
//		all done with j 27
//		all done with j 28
//		all done with j 29
//		all done with j 30
//		all done with j 31
//		all done with j 32
//		all done with j 33
//		all done with j 34
//		all done with j 35
//		all done with j 36
//		all done with j 37
//		all done with j 38
//		all done with j 39
//		all done with j 40
//		all done with j 41
//		all done with j 42
//		all done with j 43
//		all done with j 44
//		all done with j 45
//		all done with j 46
//		all done with j 47
//		all done with j 48
//		all done with j 49
//		all done with j 50
//		all done with j 51
//		all done with j 52
//		all done with j 53
//		all done with j 54
//		all done with j 55
//		all done with j 56
//		all done with j 57
//		all done with j 58
//		all done with j 59
//		all done with j 60
//		all done with j 61
//		all done with j 62
//		all done with j 63
//		all done with j 64
//		all done with j 65
//		all done with j 66
//		all done with j 67
//		all done with j 68
//		all done with j 69
//		all done with j 70
//		all done with j 71
//		all done with j 72
//		all done with j 73
//		all done with j 74
//		all done with j 75
//		all done with j 76
//		all done with j 77
//		all done with j 78
//		all done with j 79
//		all done with j 80
//		all done with j 81
//		all done with j 82
//		all done with j 83
//		all done with j 84
//		all done with j 85
//		all done with j 86
//		all done with j 87
//		all done with j 88
//		all done with j 89
//		all done with j 90
//		all done with j 91
//		all done with j 92
//		all done with j 93
//		all done with j 94
//		all done with j 95
//		all done with j 96
//		all done with j 97
//		all done with j 98
//		all done with j 99
//
//		"""
//		#expect(output.stdout == expected)
	}
}
