//
//  BenchTest.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/22/24.
//

import Testing

struct BenchTests: VMTest {
	@Test("Basic") func basic() throws {
		let code = #"""
		protocol Greetable {
			var name: String
		}

		protocol Greeter {
			func greet(name: Greetable) -> String
		}

		struct Person: Greeter, Greetable {
			var name: String

			func greet(greetable: Greetable) -> String {
				"Oh hi, " + greetable.name + ", it's me " + self.name
			}
		}

		struct Animal: Greetable {
			var name: String
		}

		// TODO: it's be nice to infer array types based on first use?
		var people = [Person("Pat")]
		var animals  = [Animal("Pooch")]

		let count = 100
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
			print(person.greet(name: animal))
			i = i + 1
		}

		print("all done")

		"""#

		let output = TestOutput()
		_ = try run(code, output: output)

		#expect(output.stdout == (0..<100).map { "Oh hi, Animal \($0), it's me Person \($0)" }.joined(separator: "\n") + "\n")
	}
}
