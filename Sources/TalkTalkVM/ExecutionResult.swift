//
//  ExecutionResult.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/9/24.
//

import TalkTalkBytecode

public extension VirtualMachine {
	enum ExecutionResult: Sendable {
		case ok(Value), error(String)

		public func error() -> String? {
			switch self {
			case .ok(_):
				return nil
			case .error(let string):
				return string
			}
		}

		public func get() -> Value {
			switch self {
			case .ok(let value):
				return value
			case .error(let string):
				fatalError("Execution error: \(string)")
			}
		}
	}
}
