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

class Context {
	// If this context isn't top level we can use its parent to look stuff up
	let parent: Context?

	// Contexts that have been imported
	let imports: [Context]

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

	// Diagnostics
	var diagnostics: [Diagnostic] = []

	// Should we log everything?
	var verbose: Bool = false

	// A set of type variables introduced in this context
	var variables: Set<VariableID> = []

	let lexicalScope: (any MemberOwner)?

	init(parent: Context? = nil, lexicalScope: (any MemberOwner)?, imports: [Context] = [], verbose: Bool = false) {
		self.parent = parent
		self.children = []
		self.imports = imports
		self.verbose = verbose
		self.lexicalScope = lexicalScope
	}

	func error(_ message: String, at location: SourceLocation) {
		if let parent {
			parent.error(message, at: location)
		} else {
			log(message, prefix: " ! ")

			diagnostics.append(
				Diagnostic(message: message, severity: .error, location: location)
			)
		}
	}

	func solve() -> Context {
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

	subscript(_ syntax: any Syntax, file: String = #file, line: UInt32 = #line) -> InferenceType? {
		if let result = environment[syntax.id] {
			return applySubstitutions(to: result, file: file, line: line)
		} else {
			return nil
		}
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

	func type(named name: String, includeParents: Bool = true, includeBuiltins: Bool = true) -> InferenceResult? {
		if includeBuiltins {
			// Handle builtin types
			switch name {
			case "int":
				return .type(.base(.int))
			case "String":
				return .type(.base(.string))
			case "bool":
				return .type(.base(.bool))
			case "pointer":
				return .type(.base(.pointer))
			default:
				()
			}
		}

		if let builtin = BuiltinFunction.map[name] {
			return .type(builtin.type)
		}

		// See if we have it in this context
		if let result = names[name] {
			return result
		}

		if let type = lexicalScope as? StructType, let typeParam = type.typeParameters[name] {
			return .type(.typeVar(typeParam))
		}

		if includeParents {
			return parent?.type(named: name)
		}

		return nil
	}

	func addChild(lexicalScope: (any MemberOwner)? = nil) -> Context {
		let child = Context(parent: self, lexicalScope: lexicalScope)
		children.append(child)
		return child
	}

	func variable(named name: String) -> InferenceResult? {
		names[name] ?? parent?.variable(named: name)
	}

	func addConstraint(_ constraint: any Constraint) {
		constraints.append(constraint)
	}

	func define(_ name: String, as result: InferenceResult) {
		if case let .type(.placeholder(typeVar)) = names[name] {
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
			substitutions[typeVar] = .type(type)
		case let (.base(lhs), .base(rhs)) where lhs != rhs:
			self.error("Cannot unify \(lhs) and \(rhs)", at: location)
		default:
			()
		}
	}

	func bind(_ typeVariable: TypeVariable, to type: InferenceType) throws {
		if typeVariable.isGeneric {
			return
		}

		// TODO: Do we need this?
		try parent?.bind(typeVariable, to: type)

		substitutions[typeVariable] = .type(type)
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
		let type: InferenceResult = (parent?.applySubstitutions(to: type)).flatMap { .type($0) } ?? type
		let result = type.instantiate(in: self, file: file, line: line)

		return applySubstitutions(to: result.type, with: substitutions, count: count, file: file, line: line)
	}

	func applySubstitutions(to type: InferenceType, with substitutions: [TypeVariable: InferenceResult], count: Int = 0, file: String = #file, line: UInt32 = #line) -> InferenceType {
		switch type {
		case .typeVar(let typeVariable), .placeholder(let typeVariable):
			// Reach down recursively as long as we can to try to find the result
			if count < 10, case let .type(.typeVar(child)) = findParentSubstitution(for: typeVariable) {
				return applySubstitutions(to: .type(.typeVar(child)), with: substitutions, count: count + 1)
			}

			return findParentSubstitution(for: typeVariable)?.instantiate(in: self).type ?? type
		case .function(let params, let returns):
			return .function(
				params.map {
					.type(applySubstitutions(to: $0, with: substitutions))
				},
				.type(applySubstitutions(to: returns, with: substitutions))
			)
		case .instance(var instance):
			for case let (variable, .typeVar(replacement)) in instance.substitutions {
				instance.substitutions[variable] = substitutions[replacement]?.instantiate(in: self).type
			}

			return .instance(instance)
		case .self(let type):
			()
		case .struct(_):
			() // Structs are meant to be blueprints so they should not get replacements. Instances should.
		case .instanceV1(_):
			()
		case .instantiatable(_):
			()
		case .instancePlaceholder(_):
			()
		case .kind(_):
			()
		case .selfVar(_):
			()
		case .enumCase(_):
			()
		case .pattern(_):
			()
		case .void, .any, .base:
			()
		default:
			log("Unhandled substitution: \(type.debugDescription)", prefix: " ! ")
		}

		return type
	}

	func instantiate(_ scheme: Scheme, with substitutions: [TypeVariable: InferenceType] = [:], file: String = #file, line: UInt32 = #line) -> (InferenceType, [TypeVariable: InferenceType]) {
		var substitutions: [TypeVariable: InferenceType] = substitutions

//		if case let .struct(type) = scheme.type {
//			for typeParameter in type.typeParameters.values {
//				substitutions[typeParameter] = .type(.typeVar(freshTypeVariable(typeParameter.name ?? "<unnamed>", file: file, line: line)))
//			}
//		}

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

	func log(_ msg: String, prefix: String, context: InferenceContext? = nil) {
		if isVerbose() {
			var depth = 0
			var nextParent = self.parent
			while let parent = nextParent {
				depth += 1
				nextParent = parent.parent
			}

			print("\(depth) \(String(repeating: "\t", count: max(0, depth - 1)))" + prefix + msg)
		}
	}

	func isVerbose() -> Bool {
		verbose || parent?.isVerbose() ?? false
	}
}
