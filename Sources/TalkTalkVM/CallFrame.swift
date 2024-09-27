//
//  CallFrame.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/4/24.
//

import OrderedCollections
import TalkTalkBytecode

struct Closure {
	var chunk: StaticChunk
	var capturing: [StaticSymbol: Capture.Location]

	public init(chunk: StaticChunk, capturing: [StaticSymbol: Capture.Location]) {
		self.chunk = chunk
		self.capturing = capturing
	}
}

public class CallFrame {
	var isInline: Bool = false
	var closure: Closure
	var returnTo: UInt64
	var locals: [String: Value] = [:]
	var selfValue: Value?
	let stackOffset: Int

	var patternBindings: [StaticSymbol: Value] = [:]

	init(closure: Closure, returnTo: UInt64, selfValue: Value?, stackOffset: Int) {
		self.closure = closure
		self.returnTo = returnTo
		self.selfValue = selfValue
		self.stackOffset = stackOffset
	}

	public func updateCapture(_ symbol: StaticSymbol, to location: Capture.Location) {
		if closure.capturing[symbol] != nil {
			closure.capturing[symbol] = location
			print("Updated capture location \(symbol) to \(location)")
		} else {
			print("Closure \(closure.chunk.name) does not capture \(symbol). Captures: \(closure.capturing)")
		}
	}

	func lookup(_ symbol: StaticSymbol) -> Value? {
		if let name = symbol.name {
			return locals[name]
		}

		return nil
	}

	func define(_ symbol: StaticSymbol, as value: Value) {
		if let name = symbol.name {
			locals[name] = value
		}
	}
}
