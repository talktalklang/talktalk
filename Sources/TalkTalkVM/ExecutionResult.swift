//
//  ExecutionResult.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/9/24.
//

import TalkTalkBytecode

public extension VirtualMachine {
	enum ExecutionResult: Sendable {
		enum Error: Swift.Error {
			case error(String)
		}

		case ok(Value), error(String)

		public func error() -> String? {
			switch self {
			case .ok(_):
				return nil
			case .error(let string):
				return string
			}
		}

		public func get() throws -> Value {
			switch self {
			case .ok(let value):
				return value
			case .error(let string):
				throw Error.error(string)
			}
		}
	}
}
