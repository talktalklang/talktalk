//
//  Emitted.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

public extension LLVM {
	protocol Emitted {}
}

public extension LLVM.Emitted {
	func asValue<E: LLVM.EmittedValue>(of _: E.Type) -> E? {
		if let emitted = self as? E {
			return emitted
		}

		return nil
	}
}
