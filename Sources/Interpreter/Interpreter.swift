//
//  Interpreter.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 10/24/24.
//

import TalkTalkCore
import TypeChecker

public enum ReturnValue: Equatable {
	case value(Value), returning(Value), void

	func asValue() throws -> Value {
		switch self {
		case .value(let value):
			return value
		case .returning(let value):
			return value
		case .void:
			throw RuntimeError.invalidOperation("\(self) is not a value")
		}
	}

	var isTruthy: Bool {
		switch self {
		case let .returning(value):
			value == .bool(true)
		case let .value(value):
			value == .bool(true)
		case .void:
			false
		}
	}
}

struct Binding: Equatable {
	var value: Value

	init(value: Value) {
		self.value = value
	}
}

struct Closure {
	let syntax: FuncExprSyntax
	let context: InterpreterContext
}

public class InterpreterContext: Equatable {
	public static func ==(lhs: InterpreterContext, rhs: InterpreterContext) -> Bool {
		lhs.locals == rhs.locals
	}

	var parent: InterpreterContext?

	private var locals: [String: Binding]
	private var closures: [SyntaxID: Closure] = [:]

	init(parent: InterpreterContext? = nil, locals: [String: Binding] = [:]) {
		self.parent = parent
		self.locals = locals
	}

	func closure(_ id: SyntaxID) -> (FuncExprSyntax, InterpreterContext)? {
		if let closure = closures[id] {
			return (closure.syntax, closure.context)
		}

		return parent?.closure(id)
	}

	func defineClosure(syntax: FuncExprSyntax, closure: InterpreterContext) -> Value {
		closures[syntax.id] = .init(syntax: syntax, context: closure)
		return .fn(syntax.id)
	}

	func assign(_ value: Value, to name: String) {
		if locals[name] != nil {
			locals[name] = .init(value: value)
			return
		}

		parent?.assign(value, to: name)
	}

	func binding(named name: String) -> Binding? {
		locals[name] ?? parent?.binding(named: name)
	}

	func lookup(_ name: String) -> Value? {
		locals[name]?.value ?? parent?.lookup(name)
	}

	func child(locals: [String: Binding] = [:]) -> InterpreterContext {
		InterpreterContext(parent: self, locals: locals)
	}

	func bind(_ name: String, to value: Value) {
		locals[name] = .init(value: value)
	}
}

public struct Interpreter: Visitor {
	public typealias Context = InterpreterContext
	public typealias Value = ReturnValue

	var typeContext: TypeChecker.Context

	public init(typeContext: TypeChecker.Context) {
		self.typeContext = typeContext
	}

	public func run(_ syntax: [Syntax]) async throws -> ReturnValue {
		let context = InterpreterContext()
		return try syntax.reduce(into: ReturnValue.void) {
			$0 = try $1.accept(self, context)
		}
	}

	// MARK: Visits

	public func visit(_ syntax: CallExprSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		let callee = try syntax.callee.accept(self, context).asValue()
		let args = try syntax.args.map { try $0.accept(self, context).asValue() }

		if callee.isCallable {
			return try callee.call(with: args, interpreter: self, in: context)
		}

		throw RuntimeError.invalidOperation("Cannot call \(callee)")
	}

	public func visit(_ syntax: DefExprSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		guard case let .value(val) = try syntax.value.accept(self, context) else {
			throw RuntimeError.invalidOperation("Invalid assignment value: \(syntax.receiver)")
		}

		switch syntax.receiver {
		case let receiver as VarExprSyntax:
			context.assign(val, to: receiver.name)
			return .void
		default:
			()
		}

		throw RuntimeError.invalidOperation("Cannot assign to \(syntax.receiver)")
	}

	public func visit(_: IdentifierExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_ expr: LiteralExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		switch expr.value {
		case let .int(value):
			.value(.int(value))
		case let .string(value):
			.value(.string(value))
		case let .bool(val):
			.value(.bool(val))
		case .nil:
			.value(.nil)
		}
	}

	public func visit(_ syntax: VarExprSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		if let value = context.lookup(syntax.name) {
			return .value(value)
		} else {
			throw RuntimeError.missingValue("Undefined variable: \(syntax.name)")
		}
	}

	public func visit(_: UnaryExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_ expr: BinaryExprSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		let lhs = try expr.lhs.accept(self, context)
		let rhs = try expr.rhs.accept(self, context)

		return try .value(lhs.asValue().apply(expr.op, with: rhs.asValue()))
	}

	public func visit(_ syntax: IfExprSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		let condition = try syntax.condition.accept(self, context)

		if condition.isTruthy {
			return try syntax.consequence.accept(self, context)
		} else {
			return try syntax.alternative.accept(self, context)
		}
	}

	public func visit(_ syntax: WhileStmtSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		while try syntax.condition.accept(self, context).isTruthy {
			if case let .returning(val) = try syntax.body.accept(self, context) {
				return .returning(val)
			}
		}

		return .void
	}

	public func visit(_ syntax: BlockStmtSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		var returnValue: ReturnValue?

		for stmt in syntax.stmts {
			let returns = try stmt.accept(self, context)

			if case .returning = returns {
				return returns
			} else {
				returnValue = returns
			}
		}

		return returnValue ?? .value(.string("sup"))
	}

	public func visit(_ syntax: FuncExprSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		let closure = context.defineClosure(syntax: syntax, closure: context)

		if let name = syntax.name?.lexeme {
			context.bind(name, to: closure)
		}

		return .value(closure)
	}

	public func visit(_: ParamsExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: ParamSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: GenericParamsSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_ arg: Argument, _ context: InterpreterContext) throws -> ReturnValue {
		try arg.value.accept(self, context)
	}

	public func visit(_: StructExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: DeclBlockSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_ syntax: VarDeclSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		if case let .value(val) = try syntax.value?.accept(self, context) {
			context.bind(syntax.name, to: val)
		}

		return .void
	}

	public func visit(_ syntax: LetDeclSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		if case let .value(val) = try syntax.value?.accept(self, context) {
			context.bind(syntax.name, to: val)
		}

		return .void
	}

	public func visit(_: ParseErrorSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: MemberExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_ syntax: ReturnStmtSyntax, _ context: InterpreterContext) throws -> ReturnValue {
    if case let .value(val) = try syntax.value?.accept(self, context) {
      return .returning(val)
    } else {
      return .returning(.nil)
    }
	}

	public func visit(_: InitDeclSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: ImportStmtSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: TypeExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_ expr: ExprStmtSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		try expr.expr.accept(self, context)
	}

	public func visit(_ syntax: IfStmtSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		let result = if try syntax.condition.accept(self, context).isTruthy {
			try syntax.consequence.accept(self, context)
		} else if let alternative = syntax.alternative {
			try alternative.accept(self, context)
		} else {
			ReturnValue.void
		}

		return result
	}

	public func visit(_: StructDeclSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: ArrayLiteralExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: SubscriptExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: DictionaryLiteralExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: DictionaryElementExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: ProtocolDeclSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: ProtocolBodyDeclSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: FuncSignatureDeclSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: EnumDeclSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: EnumCaseDeclSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: MatchStatementSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: CaseStmtSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: EnumMemberExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: InterpolatedStringExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: ForStmtSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: LogicalExprSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_ expr: GroupedExprSyntax, _ context: InterpreterContext) throws -> ReturnValue {
		try expr.expr.accept(self, context)
	}

	public func visit(_: LetPatternSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: PropertyDeclSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}

	public func visit(_: MethodDeclSyntax, _: InterpreterContext) throws -> ReturnValue {
		fatalError("TODO")
	}
}
