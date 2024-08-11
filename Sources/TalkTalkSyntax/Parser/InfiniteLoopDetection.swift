//
//  Parser+InfiniteLoopDetection.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
extension Parser {
	mutating func checkForInfiniteLoop() {
		parserRepeats[current.start, default: 0] += 1

		if parserRepeats[current.start]! > 100 {
			print("Infinite loop detect at \(current.debugDescription), advancing.")
			advance()
		}
	}
}
