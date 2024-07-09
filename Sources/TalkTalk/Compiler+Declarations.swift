//
//  Compiler+Declarations.swift
//
//
//  Created by Pat Nakajima on 7/7/24.
//
extension Compiler {
	func declaration() {
		parser.skip(.statementTerminators)

		if parser.match(.func) {
			funcDeclaration()
		} else if parser.match(.class) {
			classDeclaration()
		} else if parser.match(.var) {
			varDeclaration()
		} else {
			statement()
		}
	}

	func funcDeclaration() {
		let global = parseVariable("Expected function name.")
		markInitialized()
		function(kind: .function)
		defineVariable(global: global)
	}

	func classDeclaration() {
		parser.consume(.identifier, "Expected class name")

		let className = parser.previous!

		let nameConstant = identifierConstant(className)
		declareVariable()

		emit(opcode: .class)
		emit(nameConstant)
		defineVariable(global: nameConstant)

		let currentClass = ClassCompiler()
		self.currentClass?.parent = currentClass
		self.currentClass = currentClass

		if parser.match(.colon) {
			parser.consume(.identifier, "Expected inheritance name")

			if className.same(lexeme: parser.previous, in: source) {
				error("type cannot inherit from self", at: className)
				return
			}

			variable(false)

			beginScope()
			addLocal(name: .synthetic(.super, length: 5))
			defineVariable(global: 0)

			// Emit the superclass name so it can be inherited from
			namedVariable(className, false)

			emit(opcode: .inherit)
			currentClass.hasSuperclass = true
		}

		// Add the class name back to the top of the stack so methods can
		// access it
		namedVariable(className, false)

		parser.skip(.newline)
		parser.consume(.leftBrace, "Expected '{' before class body")
		parser.skip(.newline)

		while !parser.check(.rightBrace), !parser.check(.eof) {
			// Field declarations will go here too
			parser.skip(.newline)

			#if DEBUG
				checkForInfiniteLoop()
			#endif

			if parser.match(.var) { computedProperty() }
			if parser.match(.func) { method() }
			if parser.match(.`init`) { initializer() }

			parser.skip(.newline)
		}

		parser.consume(.rightBrace, "Expected '}' after class body")

		// Pop the class name back off
		emit(opcode: .pop)

		if currentClass.hasSuperclass {
			endScope()
		}

		self.currentClass = currentClass.parent
	}

	func computedProperty() {
		parser.consume(.identifier, "Expected property name")

		// Get the constant byte for the property's name
		let name = identifierConstant(parser.previous)

		// Parse/emit the body, including parameters
		function(kind: .computedProperty)

		// Emit the code
		emit(opcode: .computedProperty)
		emit(name)
	}

	func initializer() {
		// Get the constant byte for the method's name
		let name = chunk.make(constant: .string("init"))

		// Parse/emit the body, including parameters
		function(kind: .initializer)

		// Emit the code
		emit(opcode: .method)
		emit(name)
	}

	func method() {
		parser.consume(.identifier, "Expected method name")

		// Get the constant byte for the method's name
		let name = identifierConstant(parser.previous)

		// Parse/emit the body, including parameters
		function(kind: .method)

		// Emit the code
		emit(opcode: .method)
		emit(name)
	}

	func varDeclaration() {
		let global = parseVariable("Expected variable name")

		defer {
			defineVariable(global: global)
		}

		if parser.match(.equal) {
			expression()
		} else {
			emit(opcode: .nil)
		}

		parser.consume(.statementTerminators, "Expected ';' or new line after variable declaration")
	}
}
