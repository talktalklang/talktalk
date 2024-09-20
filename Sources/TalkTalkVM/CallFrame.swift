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
	var capturing: [Symbol: Capture.Location]

	public init(chunk: StaticChunk, capturing: [Symbol: Capture.Location]) {
		self.chunk = chunk
		self.capturing = capturing
	}
}

public class CallFrame {
	var isInline: Bool = false
	var closure: Closure
	var returnTo: UInt64
	var locals: OrderedDictionary<String, Value> = [:]
	var selfValue: Value?
	let stackOffset: Int

	var patternBindings: [Symbol: Value] = [:]

	init(closure: Closure, returnTo: UInt64, selfValue: Value?, stackOffset: Int) {
		self.closure = closure
		self.returnTo = returnTo
		self.selfValue = selfValue
		self.stackOffset = stackOffset
	}

	public func updateCapture(_ symbol: Symbol, to location: Capture.Location) {
		if closure.capturing[symbol] != nil {
			closure.capturing[symbol] = location
			print("Updated capture location \(symbol) to \(location)")
		} else {
			print("Closure \(closure.chunk.name) does not capture \(symbol). Captures: \(closure.capturing)")
		}
	}

	func lookup(_ symbol: Symbol) -> Value? {
		switch symbol.kind {
		case let .function(name, _):
			locals[name]
		case let .value(name):
			locals[name]
		default:
			nil
		}
	}

	func define(_ symbol: Symbol, as value: Value) {
		switch symbol.kind {
		case let .function(name, _):
			locals[name] = value
		case let .value(name):
			locals[name] = value
		default:
			()
		}
	}
}
