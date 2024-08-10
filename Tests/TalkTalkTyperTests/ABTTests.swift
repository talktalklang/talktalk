//
//  ABTTests.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

import TalkTalkSyntax
import TalkTalkTyper
import Testing

struct ABTTests {
	func ast(_ string: String) -> ProgramSyntax {
		let sourceFile = SourceFile(path: "ABTTests.tlk", source: string)
		return try! SyntaxTree.parse(source: sourceFile)
	}

	@Test("Binds String with let") func letString() {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo = "sup"
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.scope.locals["foo"]!.type.description == "String")
	}

	@Test("Binds String with var") func varString() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = "sup"
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.scope.locals["foo"]!.type.description == "String")
	}

	@Test("Binds Int with let") func letInt() {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo = 123
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.scope.locals["foo"]!.type.description == "Int")
	}

	@Test("Cannot reassign a `let`") func letReassign() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo = 123
		foo = 456
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].message.contains("Cannot reassign"))
	}

	@Test("Can assign a let before it's been assigned") func letAssign() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo
		foo = 456
		""")).visit()

		#expect(abt.scope.errors.isEmpty)
		#expect(abt.scope.locals["foo"]?.type.description == "Int")
	}

	@Test("Can reassign a var") func varReassign() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = 123
		foo = 456
		""")).visit()

		#expect(abt.scope.errors.isEmpty)
		#expect(abt.scope.locals["foo"]?.type.description == "Int")
	}

	@Test("Binds String with var") func varInt() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = 123
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.scope.locals["foo"]!.type.description == "Int")
	}

	@Test("Binds Bool with let") func letBool() {
		let abt = SemanticASTVisitor(ast: ast("""
		let foo = true
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.scope.locals["foo"]!.type.description == "Bool")
	}

	@Test("Binds String with var") func varBool() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = true
		""")).visit()

		let decl = abt.cast(Program.self).declarations[0]
		#expect(decl.syntax.start.start == 0)
		#expect(decl.scope.locals["foo"]!.type.description == "Bool")
	}

	@Test("Does not bind when type decl and expr dont agree") func declConflict() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo: Bool = 123
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].location.description.contains("foo"))
		#expect(abt.scope.errors[0].message.contains("Cannot assign"))
	}

	@Test("Error when trying to assign to wrong type") func badAssign() {
		let abt = SemanticASTVisitor(ast: ast("""
		var foo = 123
		foo = "error"
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].location.description.contains("foo"))
		#expect(abt.scope.errors[0].message.contains("Cannot assign"))
	}

	@Test("Errors on undeclared var") func undeclaredVar() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		foo = 123
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].location.description.contains("foo"))
		#expect(abt.scope.errors[0].message.contains("Undefined variable"))
	}

	@Test("Infer function return value") func inferFuncReturn() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		func foo() {
			123
		}
		""")).visit()

		#expect(abt.scope.locals["foo"]!.type.description == "Function() -> (Int)")
	}

	@Test("Error when function type decl that's not inferred return") func inferFuncBadReturn() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		func foo() -> String {
			123
		}
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].location.description.contains("foo"))
		#expect(abt.scope.errors[0].message.contains("Cannot return Int"))
	}

	@Test("Infer parameter type from return val") func inferParamterFromReturnVal() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		func foo(a) -> Int {
			a
		}
		""")).visit()

		#expect(abt.scope.errors.isEmpty)

		#expect(abt.scope.locals["a"]?.name == nil)

		let decl = abt.cast(Program.self).declarations[0]

		let varA = decl.scope.locals["a"]!
		#expect(varA.inferedTypeFrom != nil)
		#expect(varA.type.description == "Int")
		#expect(decl.scope.depth == 1)

		#expect(abt.scope.locals["foo"]!.type.description == "Function(a: Int) -> (Int)")
	}

	@Test("If statement") func ifStmt() {
		let abt = SemanticASTVisitor(ast: ast("""
		func foo(n) {
			if false {
				return n + 1
			}

			return n
		}
		""")).visit()

		#expect(abt.scope.errors.isEmpty)

		#expect(abt.scope.locals["foo"]?.type.description == "Function(n: Int) -> (Int)")

		let fn = abt.scope.locals["foo"]!.node.cast(Function.self)
		let local = fn.scope.locals["n"]!
		#expect(local.type.description == "Int")
	}

	@Test("If expression") func ifExpr() {
		let abt = SemanticASTVisitor(ast: ast("""
		var a = if false {
			123
		} else {
			456
		}
		""")).visit()

		#expect(abt.scope.errors.isEmpty)

		#expect(abt.scope.locals["a"]?.type.description == "Int")

		let decl = abt.cast(Program.self).declarations[0].cast(VarLetDeclaration.self)
		let expression = decl.expression!.cast(IfExpression.self)
		#expect(expression.type.description == "Int")
	}

	@Test("If expression with unmatched branches") func ifExprUnmatching() {
		let abt = SemanticASTVisitor(ast: ast("""
		var a = if false {
			123
		} else {
			"sup"
		}
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].message.contains("must match"))
	}

	@Test("If expression w/out boolean condition") func ifExprNonBool() {
		let abt = SemanticASTVisitor(ast: ast("""
		var a = if "yo" {
			123
		} else {
			4567
		}
		""")).visit()

		#expect(!abt.scope.errors.isEmpty)
		#expect(abt.scope.errors[0].message.contains("must be Bool"))
	}

	@Test("Int binary expressions") func intbinary() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		1 + 1
		""")).visit().cast(Program.self).declarations[0].cast(BinaryOpExpression.self)

		#expect(abt.type.description == "Int")
		#expect(abt.lhs.type.description == "Int")
		#expect(abt.rhs.type.description == "Int")
	}

	@Test("Errors on binary type mismatch") func binarytypeMismatch() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		1 + "sup"
		""")).visit()

		#expect(abt.scope.errors[0].message.contains("must match"))
	}

	@Test("Infers types from binary ops") func binarytypeInfer() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		func foo(i) {
			i * 2
		}
		""")).visit()

		#expect(abt.scope.errors.isEmpty)
		#expect(abt.scope.locals["i"]?.name == nil)

		let decl = abt.cast(Program.self).declarations[0]

		let varI = decl.scope.locals["i"]!
		#expect(varI.inferedTypeFrom != nil)
		#expect(varI.type.description == "Int")
		#expect(decl.scope.depth == 1)

		#expect(abt.scope.locals["foo"]!.type.description == "Function(i: Int) -> (Int)")

		let children = decl.cast(Function.self).body.children
		#expect(children.count == 1)
		#expect(children[0].type.description == "Int")
	}

	@Test("Functions returning inferred values") func functionsReturningInferred() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		func fib(n) {
			if (n <= 1) {
				return n
			}

			return fib(n - 2) + fib(n - 1)
		}
		""")).visit()

		#expect(abt.scope.errors.isEmpty)

		let fun = abt.scope.locals["fib"]!
		#expect(fun.type.description == "Function(n: Int) -> (Int)")
	}

	@Test("foistin'", .disabled()) func foist() throws {

	}

	@Test("captures locals") func captures() throws {
		let abt = SemanticASTVisitor(ast: ast("""
		func print(any) {}

		func main() {
			var foo = "sup"
			func bar() {
				print(foo)
			}
		}

		func fizz() {
			// No captures here.
		}
		""")).visit()

		#expect(abt.scope.errors.isEmpty)

		let bar = abt.declarations[1]
			.cast(Function.self)
			.body.children[1].cast(Function.self)

		#expect(bar.scope.lookup(identifier: "foo")?.type.description == "String")
	}

	@Test("function capture") func fnCapture() {
		let abt = SemanticASTVisitor(ast: ast("""
		func main() {
			var i = 123

			func bar() {
				i = i + 1
			}

			return bar
		}
		""")).visit()

		let main = abt.scope.locals["main"]!.node

		#expect(abt.scope.errors.isEmpty)
		#expect(main.type.description == "Function() -> (Function() -> (Int))")
		#expect(main.cast(Function.self).scope.locals["bar"]?.type.description == "Function() -> (Int)")
		#expect(abt.scope.locals["bar"] == nil)

		let ivar = main.scope.lookup(identifier: "i")!
		#expect(ivar.isEscaping == true)

		let bar = main.scope.lookup(identifier: "bar")!
		#expect(bar.isEscaping == true)
		#expect(bar.node.cast(Function.self).body.captures["i"]?.node.is(ivar.node) == true)
	}

	@Test("Counter") func counter() {
		let abt = SemanticASTVisitor(ast: ast("""
		// Test closures
		func makeCounter() {
			var i = 0

			func count() {
				i = i + 1
				i
			}

			return count
		}

		var counter = makeCounter()
		counter()
		counter()
		""")).visit()

		let makeCounter = abt.scope.locals["makeCounter"]!
		#expect(makeCounter.type.description == "Function() -> (Function() -> (Int))")

		let makeCounterFunction = makeCounter.node.cast(Function.self)
		#expect(makeCounterFunction.body.children.count == 3)
		#expect(makeCounterFunction.scope.captures().map(\.key) == [])
		#expect(makeCounterFunction.scope.locals.map(\.key).sorted() == ["i", "count"].sorted())

		let count = makeCounterFunction.scope.lookup(identifier: "count")!
		#expect(count.isEscaping)
		#expect(count.node.scope.captures().map(\.key).sorted() == ["count", "i"].sorted())


		let countFunction = count.node.cast(Function.self)
		#expect(countFunction.body.children.count == 2)
		#expect(countFunction.body.children[0].syntax.description == "i = i + 1")
		#expect(countFunction.body.children[0].type.description == "Int")
		#expect(countFunction.body.children[1].syntax.description == "i")
	}
}
