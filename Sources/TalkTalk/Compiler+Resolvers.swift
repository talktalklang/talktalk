//
//  Compiler+Resolvers.swift
//
//
//  Created by Pat Nakajima on 7/5/24.
//
extension Compiler {
	func declareVariable() {
		if scopeDepth == 0 {
			return
		}

		let name = parser.previous!

		var i = localCount - 1
		while i >= 0, let local = locals[i] {
			if local.depth != -1, local.depth < scopeDepth {
				break // negative
			}

			if name.same(lexeme: local.name, in: source) {
				error("Already a variable with this name in this scope")
			}

			i -= 1
		}

		addLocal(name: name)
	}

	func defineVariable(global: Byte) {
		if scopeDepth > 0 {
			markInitialized()
			return
		}

		emit(opcode: .defineGlobal)
		emit(global)
	}

	func addLocal(name: Token) {
		if localCount == 256 {
			error("Too many local variables in function")
			return
		}

		locals[localCount++] = Local(name: name, depth: -1)
	}

	func markInitialized() {
		if scopeDepth == 0 {
			return
		}

		locals[localCount - 1]?.depth = scopeDepth
	}

	func namedVariable(_ token: Token, _ canAssign: Bool) {
		let getOp, setOp: Opcode

		var arg: Byte? = resolveLocal(token)
		if arg != nil {
			getOp = .getLocal
			setOp = .setLocal
		} else if let upvalue = resolveUpvalue(from: token), upvalue != -1 {
			arg = Byte(upvalue)
			getOp = .getUpvalue
			setOp = .setUpvalue
		} else {
			arg = identifierConstant(token)
			getOp = .getGlobal
			setOp = .setGlobal
		}

		guard let arg else {
			error("Could not get variable opcode", at: token)
			return
		}

		if canAssign, parser.match(.equal) {
			expression()
			emit(opcode: setOp)
			emit(arg)
		} else {
			emit(opcode: getOp)
			emit(arg)
		}
	}

	func resolveUpvalue(from token: Token) -> Int? {
		guard let parent else {
			return nil
		}

		if let localByte = parent.resolveLocal(token) {
			parent.locals[Int(localByte)]!.isCaptured = true
			return addUpvalue(index: localByte, isLocal: true)
		}

		if let upvalue = parent.resolveUpvalue(from: token), upvalue != -1 {
			return addUpvalue(index: Byte(upvalue), isLocal: false)
		}

		return nil
	}

	func identifierConstant(_ token: Token) -> Byte {
		let value = Value.string(String(token.lexeme(in: source)))
		return chunk.make(constant: value)
	}

	func beginScope() {
		scopeDepth += 1
	}

	func endScope() {
		scopeDepth -= 1

		// The block is done, gotta clean up the scope
		while localCount > 0, let local = locals[localCount - 1], local.depth > scopeDepth {
			if local.isCaptured {
				emit(opcode: .closeUpvalue)
			} else {
				emit(opcode: .pop)
			}

			localCount -= 1
		}
	}

	func resolveLocal(_ name: Token) -> Byte? {
		for i in stride(from: localCount, to: -1, by: -1) {
			guard let local = locals[i] else {
				continue
			}

			if name.same(lexeme: local.name, in: source) {
				guard local.isInitialized else {
					error("Cannot read local variable in its own initializer")
					return nil
				}

				return Byte(i)
			}
		}

		return nil
	}

	func addUpvalue(index: Byte, isLocal: Bool) -> Int {
		for (i, upvalue) in upvalues.enumerated() {
			if upvalue.index == index && upvalue.isLocal == isLocal {
				return i
			}
		}

		if function.upvalueCount == Byte.max {
			error("Too many closure variables in function")
			return -1
		}

		let upvalue = Upvalue(isLocal: isLocal, index: index)
		upvalues.append(upvalue)

		return function.upvalueCount++
	}
}
