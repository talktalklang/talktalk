//
//  RawArray.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/11/24.
//

import TalkTalkBytecode

// This is the runtime implementation of the _RawArray that backs Array from the stdlib.
// Its implementation is likely to change, thus the underscore.
extension BuiltinStructs {
	final class _RawArray: BuiltinStruct {
		static func instantiate() -> BuiltinStructs._RawArray {
			_RawArray()
		}

		var storage: ContiguousArray<Value> = []

		func getProperty(_ slot: Int) -> TalkTalkBytecode.Value {
			// TODO: make sure these match TalkTalkAnalysis.BuiltinStruct._RawArray
			switch slot {
			case 0: .int(.init(storage.count))
			default:
				fatalError("No method found at slot: \(slot) for \(self)")
			}
		}

		func arity(for methodSlot: Int) -> Int {
			switch methodSlot {
			case 1: 1
			case 2: 1
			default:
				fatalError("No method found at slot: \(methodSlot) for \(self)")
			}
		}

		func call(_ methodSlot: Int, _ args: [Value]) -> Value? {
			// TODO: make sure these match TalkTalkAnalysis.BuiltinStruct._RawArray
			switch methodSlot {
			case 1: append(args)
			case 2: at(args)
			default:
				fatalError("No method found at slot: \(methodSlot) for \(self)")
			}
		}

		func append(_ args: [Value]) -> Value? {
			storage.append(args[0])
			return nil
		}

		func at(_ args: [Value]) -> Value {
			.none
		}
	}
}
