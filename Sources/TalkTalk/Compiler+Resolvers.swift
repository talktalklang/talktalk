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

		if let name = parser.previous {
			var i = localCount
			while i >= 0 {
				guard let local = locals[i] else {
					i -= 1
					continue
				}

				if local.depth != -1, local.depth < scopeDepth {
					break
				}

				if name.same(lexeme: local.name, in: source) {
					error("Already a variable with this name in this scope")
				}

				i -= 1
			}

			addLocal(name: name)
		} else {
			error("No variable name at \(parser.current.line)")
		}
	}

	func defineVariable(global: Byte) {
		if scopeDepth > 0 {
			markInitialized()
			return
		}

		emit(.defineGlobal)
		emit(global)
	}

	func addLocal(name: Token) {
		if localCount == 256 {
			error("Too many local variables in function")
			return
		}

		locals[localCount] = Local(name: name, depth: scopeDepth)
		localCount += 1
	}

	func markInitialized() {
		if scopeDepth == 0 {
			return
		}

		locals[localCount - 1]?.isInitialized = true
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
			emit(setOp)
			emit(arg)
		} else {
			emit(getOp)
			emit(arg)
		}
	}

	func resolveUpvalue(from token: Token) -> Int? {
		guard let parent = parent else {
			return nil
		}

		if let localByte = parent.resolveLocal(token) {
			return addUpvalue(index: localByte, isLocal: true)
		}

		if let upvalue = parent.resolveUpvalue(from: token) {
			return addUpvalue(index: Byte(upvalue), isLocal: false)
		}

		return nil
	}

	func identifierConstant(_ token: Token) -> Byte {
		let value = Value.string(String(token.lexeme(in: source)))
		return compilingChunk.write(constant: value)
	}

	func beginScope() {
		scopeDepth += 1
	}

	func endScope() {
		scopeDepth -= 1

		// The block is done, gotta clean up the scope
		while localCount > 0, let local = locals[localCount - 1], local.depth > scopeDepth {
			emit(.pop)
			localCount -= 1
		}
	}

	func resolveLocal(_ name: Token) -> Byte? {
		var i = localCount - 1 // Subtracting 1 because we're indexing into an array
		while i >= 0, let local = locals[i] {
			if name.same(lexeme: local.name, in: source) {
				guard local.isInitialized else {
					error("Cannot read local variable in its own initializer")
					return nil
				}

				return Byte(i)
			}

			i -= 1
		}

		return nil
	}

	func addUpvalue(index: Byte, isLocal: Bool) -> Int {
		for i in 0 ..< currentFunction.upvalueCount where i < upvalues.count {
			let upvalue = upvalues[i]
			if upvalue.index == index && upvalue.isLocal == isLocal {
				return i
			}
		}

		if currentFunction.upvalueCount == Byte.max {
			error("Too many closure variables in function")
			return 0
		}

		let upvalue = Upvalue(isLocal: isLocal, index: index)
		upvalues.append(upvalue)

		currentFunction.upvalueCount += 1
		return currentFunction.upvalueCount
	}
}
