import Foundation

var cache: [Int: Int] = [:]

func fib(_ n: Int) -> Int {
	if n <= 1 { return n }

	if let cached = cache[n] {
		return cached
	}

	let newResult = fib(n - 2) + fib(n - 1)
	cache[n] = newResult

	return newResult
}

var start = Date().timeIntervalSince1970

var i = 0
while i < 50 {
	print(fib(i))
	i = i + 1
}

var end = Date().timeIntervalSince1970

print(end - start)
