//
//  ContextChecker.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/30/24.
//

// ok we want to traverse the tree breadth first, creating contexts for scopes and type variables for names
// seems chill?
// contexts can be nested and parents know about their children so solvers can recur through trees?
// constraint solvers can use info from their parents but parents should not see any child stuff?

import TalkTalkCore

public class Context {
	enum ContextKind {
		case normal, pattern
	}

	public let module: String

	// If this context isn't top level we can use its parent to look stuff up
	let parent: Context?

	// Contexts that have been imported
	var imports: [Context]

	// Child contexts
	var children: [Context]

	// A map of names to types that this context knows about
	var names: [String: InferenceResult] = [:]

	// Constraints added to this context
	var constraints: [any Constraint] = []

	var hoistedToParent: Set<TypeVariable> = []

	// Map of known types
	var environment: [SyntaxID: InferenceResult] = [:]

	// A map of substitutions this context knows about
	var substitutions: [TypeVariable: InferenceResult] = [:]

	// For fresh variable generation
	var nextID: VariableID = 0

	// Any time a `return` statement happens in this context, we store its result in here
	var explicitReturns: [InferenceResult] = []

	// Diagnostics that are accumulated during checking
	public private(set) var diagnostics: [Diagnostic] = []

	// Should we log everything?
	var verbose: Bool = false

	// A set of type variables introduced in this context
	var variables: Set<VariableID> = []

	// Does this context belong to a type? Like a struct or enum or something? If so it's a
	// lexical scope.
	let lexicalScope: (any MemberOwner)?

	// If we're expecting a certain type while checking, it goes here. It acts as a stack.
	var expectedTypes: [InferenceResult] = []

	// A helper
	var expectedType: InferenceResult? {
		expectedTypes.last
	}

	var kind: ContextKind = .normal

	init(
		module: String,
		parent: Context? = nil,
		lexicalScope: (any MemberOwner)?,
		imports: [Context] = [],
		verbose: Bool = false
	) {
		self.module = module
		self.parent = parent
		self.children = []
		self.imports = imports
		self.verbose = verbose
		self.lexicalScope = lexicalScope
	}

	public func `import`(_ context: Context) {
		imports.append(context)
	}

	public func get(_ syntax: any Syntax) throws -> InferenceType {
		if let result = self.find(syntax) {
			return result
		}

		throw TypeError.typeError("Type not found for \(syntax)")
	}

	public func apply(_ result: InferenceResult) -> InferenceType {
		applySubstitutions(to: result)
	}

	public subscript(_ syntax: any Syntax, file: String = #file, line: UInt32 = #line) -> InferenceType? {
		if let result = environment[syntax.id] {
			return applySubstitutions(to: result, file: file, line: line)
		} else {
			return nil
		}
	}

	func error(_ message: String, at location: SourceLocation, file: String = #file, line: UInt32 = #line) {
		if let parent {
			parent.error(message, at: location, file: file, line: line)
		} else {
			log(message + " \(file):\(line)", prefix: " ! ")

			self.diagnostic(
				Diagnostic(message: message, severity: .error, location: location)
			)
		}
	}

	func diagnostic(_ diagnostic: Diagnostic, file: String = #file, line: UInt32 = #line) {
		if let parent {
			parent.diagnostic(diagnostic, file: file, line: line)
		} else {
			log(diagnostic.message + " \(file):\(line)", prefix: " ! ")

			for subdiagnostic in diagnostic.subdiagnostics {
				log(subdiagnostic.message + " \(file):\(line)", prefix: " ! - ")
			}

			diagnostics.append(
				diagnostic
			)
		}
	}

	func solve() -> Context {
		log("Solving has begun", prefix: "---")

		for child in children {
			_ = child.solve()
		}

		while !constraints.isEmpty {
			let constraint = constraints.removeFirst()
			log("\(constraint.before)", prefix: "-> ")
			do {
				try constraint.solve()
			} catch {
				self.error(error.localizedDescription, at: constraint.location)
			}
			log("\(constraint.after)", prefix: "<- ")
		}

		return self
	}

	func retry(_ constraint: any Constraint) {
		if let parent {
			parent.retry(constraint)
			return
		}

		var constraint = constraint
		constraint.retries += 1
		constraints.append(constraint)
	}

	@discardableResult func expecting<T>(_ type: InferenceResult, perform: () throws -> T) rethrows -> T {
		expectedTypes.append(type)
		let result = try perform()
		_ = expectedTypes.popLast()
		return result
	}

	func freshID() -> VariableID {
		if let parent {
			return parent.freshID()
		}

		defer { nextID += 1 }

		return nextID
	}

	func freshTypeVariable(_ name: String, isGeneric: Bool = false, file: String = #file, line: UInt32 = #line) -> TypeVariable {
		let id = freshID()
		variables.insert(id)
		log("Fresh type variable T(\(id), \(name)) \(file):\(line)", prefix: " + ")
		return TypeVariable(name, id, isGeneric)
	}

	func builtin(named name: String) throws -> InferenceResult {
		if let result = type(named: name) {
			return result
		} else {
			throw TypeError.typeError("Could not find type named `\(name)`")
		}
	}

	func type(named name: String, includeParents: Bool = true, includeBuiltins: Bool = true) -> InferenceResult? {
		if includeBuiltins {
			// Handle builtin types
			switch name {
			case "int":
				return .resolved(.base(.int))
			case "String":
				return .resolved(.base(.string))
			case "bool":
				return .resolved(.base(.bool))
			case "pointer":
				return .resolved(.base(.pointer))
			default:
				()
			}
		}

		if let builtin = BuiltinFunction.map[name] {
			return .resolved(builtin.type)
		}

		// See if we have it in this context
		if let result = names[name] {
			return result
		}

		if let type = lexicalScope as? StructType, let typeParam = type.typeParameters[name] {
			return .resolved(.typeVar(typeParam))
		}

		if includeParents, let type = parent?.type(named: name) {
			return type
		}

		for imported in lookupImports() {
			if let result = imported.type(named: name, includeParents: includeParents, includeBuiltins: includeBuiltins) {
				return result
			}
		}

		return nil
	}

	func lookupImports() -> [Context] {
		imports + (parent?.lookupImports() ?? [])
	}

	func lookupLexicalScope() -> (any MemberOwner)? {
		if let lexicalScope {
			return lexicalScope
		}

		return parent?.lexicalScope
	}

	func addChild(lexicalScope: (any MemberOwner)? = nil) -> Context {
		let child = Context(module: module, parent: self, lexicalScope: lexicalScope)
		children.append(child)
		return child
	}

	public func find(_ syntax: any Syntax) -> InferenceType? {
		if let result = environment[syntax.id] {
			return applySubstitutions(to: result)
		}

		for child in children {
			if let result = child.find(syntax) {
				return result
			}
		}

		return nil
	}

	func variable(named name: String) -> InferenceResult? {
		names[name] ?? parent?.variable(named: name)
	}

	func addConstraint(_ constraint: any Constraint, file: String = #file, line: UInt32 = #line) {
		log("\(constraint.before) \(file):\(line)", prefix: " ⊢ ")

		constraints.append(constraint)
	}

	func define(_ name: String, as result: InferenceResult) {
		if case let .resolved(.placeholder(typeVar)) = names[name] {
			log("Defining placeholder `\(name)` as \(result.debugDescription)", prefix: " “ ")
			substitutions[typeVar] = result
		} else {
			log("Defining `\(name)` as \(result.debugDescription)", prefix: " “ ")
		}

		names[name] = result
	}

	func define(_ syntax: any Syntax, as result: InferenceResult) {
		environment[syntax.id] = result
	}

	func unify(_ lhs: InferenceType, _ rhs: InferenceType, _ location: SourceLocation, file: String = #file, line: UInt32 = #line) throws {
		let lhs = applySubstitutions(to: lhs, with: substitutions)
		let rhs = applySubstitutions(to: rhs, with: substitutions)

		if lhs == rhs {
			return
		}

		log("Unifying \(lhs) & \(rhs) \(file):\(line)", prefix: " & ")

		switch (lhs, rhs) {
		case let (.typeVar(lhs), .typeVar(rhs)):
			try bind(lhs, to: .typeVar(rhs))
			try bind(rhs, to: .typeVar(lhs))
		case let (.typeVar(typeVar), type), let (type, .typeVar(typeVar)):
			try bind(typeVar, to: type)
		case let (.placeholder(typeVar), type), let (type, .placeholder(typeVar)):
			substitutions[typeVar] = .resolved(type)
		case let (.base(lhs), .base(rhs)) where lhs != rhs:
			error("Cannot unify \(lhs) and \(rhs)", at: location)
		case var (.instance(lhs), .instance(rhs)):
			for (lhsVar, rhsVar) in zip(lhs.substitutions.values, rhs.substitutions.values) {
				try unify(lhsVar, rhsVar, location)
			}

			let substitutions = lhs.substitutions.merging(rhs.substitutions) { $1 }
			lhs.substitutions = substitutions
			rhs.substitutions = substitutions
		default:
			()
		}
	}

	func bind(_ typeVariable: TypeVariable, to type: InferenceType) throws {
		try parent?.bind(typeVariable, to: type)

		substitutions[typeVariable] = .resolved(type)
	}

	func findParentSubstitution(for typeVariable: TypeVariable) -> InferenceResult? {
		if let substitution = substitutions[typeVariable] {
			return substitution
		}

		return parent?.findParentSubstitution(for: typeVariable)
	}

	func findChildSubstitution(for typeVariable: TypeVariable) -> InferenceResult? {
		if let substitution = substitutions[typeVariable] {
			return substitution
		}

		for child in children {
			if let substitution = child.findChildSubstitution(for: typeVariable) {
				return substitution
			}
		}

		return nil
	}

	func applySubstitutions(to type: InferenceResult, file: String = #file, line: UInt32 = #line) -> InferenceType {
		applySubstitutions(to: type, with: substitutions, file: file, line: line)
	}

	func applySubstitutions(to type: InferenceType, file: String = #file, line: UInt32 = #line) -> InferenceType {
		applySubstitutions(to: type, with: substitutions, file: file, line: line)
	}

	func applySubstitutions(to type: InferenceResult, with substitutions: [TypeVariable: InferenceResult], count: Int = 0, file: String = #file, line: UInt32 = #line) -> InferenceType {
//		let type: InferenceResult = (parent?.applySubstitutions(to: type, with: substitutions)).flatMap { .type($0) } ?? type
		let result = type.instantiate(in: self, file: file, line: line)

		return applySubstitutions(to: result.type, with: substitutions, count: count, file: file, line: line)
	}

	func applySubstitutions(to type: InferenceType, with substitutions: [TypeVariable: InferenceResult], count: Int = 0, file: String = #file, line: UInt32 = #line) -> InferenceType {
		switch type {
		case let .typeVar(typeVariable), let .placeholder(typeVariable):
			// Reach down recursively as long as we can to try to find the result
			if count < 10, case let .resolved(.typeVar(child)) = substitutions[typeVariable] {
				return applySubstitutions(to: .resolved(.typeVar(child)), with: substitutions, count: count + 1)
			}

			return substitutions[typeVariable]?.instantiate(in: self).type ?? findParentSubstitution(for: typeVariable)?.instantiate(in: self).type ?? type
		case let .function(params, returns):
			return .function(
				params.map {
					.resolved(applySubstitutions(to: $0, with: substitutions))
				},
				.resolved(applySubstitutions(to: returns, with: substitutions))
			)
		case var .instance(instance):
			for case let (variable, .typeVar(replacement)) in instance.substitutions {
				if let replacement = substitutions[replacement]?.instantiate(in: self).type {
					instance.substitutions[variable] = replacement
				}
			}

			return .instance(instance)
		case let .pattern(pattern):
			return .pattern(applySubstitutions(to: pattern, with: substitutions))
		case .self:
			()
		case .type:
			() // Types are meant to be blueprints so they should not get replacements. Instances should.
		case .instancePlaceholder:
			()
		case .kind:
			()
		case .selfVar:
			()
		case .void, .any, .base:
			()
		default:
			log("Unhandled substitution: \(type.debugDescription)", prefix: " ! ")
		}

		return type
	}

	func applySubstitutions(to pattern: Pattern, with substitutions: [TypeVariable: InferenceResult]) -> Pattern {
		switch pattern {
		case let .call(type, args):
			return .call(
				.resolved(applySubstitutions(to: type, with: substitutions)),
				args.map {
					applySubstitutions(to: $0, with: substitutions)
				}
			)
		case let .value(type):
			return .value(applySubstitutions(to: type, with: substitutions))
		case let .variable(name, result):
			return .variable(name, .resolved(applySubstitutions(to: result, with: substitutions)))
		}
	}

	func instantiate(_ scheme: Scheme, with substitutions: [TypeVariable: InferenceType] = [:], file: String = #file, line: UInt32 = #line) -> (InferenceType, [TypeVariable: InferenceType]) {
		var substitutions: [TypeVariable: InferenceType] = substitutions

		// Replace the scheme's variables with fresh type variables
		for case let variable in scheme.variables {
			if let type = substitutions[variable] ?? self.substitutions[variable]?.instantiate(in: self).type {
				substitutions[variable] = type
			} else {
				let newVar = freshTypeVariable(variable.name ?? "<unnamed>", file: file, line: line)
				substitutions[variable] = .typeVar(newVar)
			}
		}

		return (
			applySubstitutions(to: scheme.type, with: substitutions.asResults),
			substitutions
		)
	}

	func depth() -> Int {
		var depth = 0
		var nextParent = parent
		while let parent = nextParent {
			depth += 1
			nextParent = parent.parent
		}

		return depth
	}

	func log(_ msg: String, prefix: String) {
		if isVerbose() {
			print("\(depth()) \(String(repeating: "\t", count: max(0, depth() - 1)))" + prefix + msg)
		}
	}

	func isVerbose() -> Bool {
		verbose || parent?.isVerbose() ?? false
	}
}
