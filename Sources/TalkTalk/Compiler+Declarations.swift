//
//  Compiler+Declarations.swift
//  
//
//  Created by Pat Nakajima on 7/7/24.
//
extension Compiler {
	func declaration() {
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

		// Add the class name back to the top of the stack so methods can
		// access it
		namedVariable(className, false)
		
		parser.consume(.leftBrace, "Expected '{' before class body")

		while !parser.check(.rightBrace), !parser.check(.eof) {
			// Field declarations will go here too

			if parser.match(.func) {
				method()
			}
		}

		parser.consume(.rightBrace, "Expected '}' after class body")

		// Pop the class name back off
		emit(opcode: .pop)

		self.currentClass = currentClass.parent
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
