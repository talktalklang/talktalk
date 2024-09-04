//
//  ExecutionResult.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/9/24.
//

import TalkTalkBytecode
import Foundation

public extension VirtualMachine {
	enum ExecutionResult: Sendable {
		public enum ReturnValue {
			case primitive(Value), object(StructInstance)
		}

		enum Error: Swift.Error {
			case error(String)
		}

		case ok(Value, TimeInterval), error(String)

		public func error() -> String? {
			switch self {
			case .ok:
				nil
			case let .error(string):
				string
			}
		}

		public func get() throws -> Value {
			switch self {
			case let .ok(value, _):
				return value
			case let .error(string):
				throw Error.error(string)
			}
		}
	}
}
