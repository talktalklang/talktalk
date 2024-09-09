//
//  CallFrame.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/4/24.
//

import TalkTalkBytecode
import OrderedCollections

struct Closure {
	var chunk: StaticChunk
	var capturing: [Symbol: Capture.Location]

	public init(chunk: StaticChunk, capturing: [Symbol: Capture.Location]) {
		self.chunk = chunk
		self.capturing = capturing
	}
}

public class CallFrame {
	var ip: UInt64 = 0
	var closure: Closure
	var returnTo: UInt64
	private(set) var locals: OrderedDictionary<String, Value> = [:]
	var selfValue: Value?

	init(closure: Closure, returnTo: UInt64, selfValue: Value?) {
		self.closure = closure
		self.returnTo = returnTo
		self.selfValue = selfValue
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
		case .function(let name, _):
			return locals[name]
		case .value(let name):
			return locals[name]
		default:
			return nil
		}
	}

	func define(_ symbol: Symbol, as value: Value) {
		switch symbol.kind {
		case .function(let name, _):
			locals[name] = value
		case .value(let name):
			locals[name] = value
		default:
			()
		}
	}
}
