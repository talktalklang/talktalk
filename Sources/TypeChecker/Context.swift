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
	var retries: [any Constraint] = []

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

	init(parent: Context? = nil, imports: [Context] = []) {
		self.parent = parent
		self.children = []
		self.imports = imports
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

		for constraint in constraints {
			log("\(constraint.before)", prefix: "-> ")
			constraint.solve()
			log("\(constraint.after)", prefix: "<- ")
		}

		for constraint in retries {
			log("\(constraint.before)", prefix: "-> ")
			constraint.solve()
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
		retries.append(constraint)
	}

	subscript(_ syntax: any Syntax) -> InferenceType? {
		if let result = environment[syntax.id] {
			return applySubstitutions(to: result)
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

	func freshTypeVariable(_ name: String, file: String = #file, line: UInt32 = #line) -> TypeVariable {
		let id = freshID()
		variables.insert(id)
		log("Fresh type variable T(\(id), \(name)) \(file):\(line)", prefix: " + ")
		return TypeVariable(name, id)
	}

	func type(named name: String, includeParents: Bool = true) -> InferenceResult? {
		if let result = names[name] {
			return result
		}

		if includeParents {
			return parent?.type(named: name)
		}

		return nil
	}

	func addChild() -> Context {
		let child = Context(parent: self)
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
			log("Defining placeholder `\(name)` as \(result)", prefix: " “ ")
			substitutions[typeVar] = result
		} else {
			log("Defining `\(name)` as \(result)", prefix: " “ ")
		}

		names[name] = result
	}

	func define(_ syntax: any Syntax, as result: InferenceResult) {
		environment[syntax.id] = result
	}

	func unify(_ lhs: InferenceResult, _ rhs: InferenceResult) {
		let lhs = applySubstitutions(to: lhs)
		let rhs = applySubstitutions(to: rhs)

		log("Unifying \(lhs) & \(rhs)", prefix: " & ")

		switch (lhs, rhs) {
		case let (.typeVar(typeVar), type), let (type, .typeVar(typeVar)):
			substitutions[typeVar] = .type(type)
		case let (.placeholder(typeVar), type), let (type, .placeholder(typeVar)):
			substitutions[typeVar] = .type(type)
		default:
			()
		}
	}

	func findParentSubstitution(for typeVariable: TypeVariable) -> InferenceResult? {
		if let substitution = substitutions[typeVariable] {
			return substitution
		}

		return parent?.findChildSubstitution(for: typeVariable)
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

	func applySubstitutions(to type: InferenceResult) -> InferenceType {
		applySubstitutions(to: type, with: substitutions)
	}

	func applySubstitutions(to type: InferenceResult, with substitutions: [TypeVariable: InferenceResult], count: Int = 0) -> InferenceType {
		let result: InferenceResult = (parent?.applySubstitutions(to: type)).flatMap { .type($0) } ?? type
		let type = result.instantiate(in: self)

		switch type {
		case .typeVar(let typeVariable), .placeholder(let typeVariable):
			// Reach down recursively as long as we can to try to find the result
			if count < 100, case let .type(.typeVar(child)) = substitutions[typeVariable] {
				return applySubstitutions(to: .type(.typeVar(child)), with: substitutions, count: count + 1)
			}

			return findParentSubstitution(for: typeVariable)?.instantiate(in: self) ?? findChildSubstitution(for: typeVariable)?.instantiate(in: self) ?? type
		case .function(let params, let returns):
			return .function(
				params.map {
					.type(applySubstitutions(to: $0, with: substitutions))
				},
				.type(applySubstitutions(to: returns, with: substitutions))
			)
		case .instance(_):
			()
		case .instantiatable(_):
			()
		case .placeholder(_):
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
		default:
			return type
		}

		return type
	}

	func instantiate(_ scheme: Scheme) -> InferenceType {
		var localSubstitutions: [TypeVariable: InferenceResult] = [:]

		// Replace the scheme's variables with fresh type variables
		for case let variable in scheme.variables {
			if let type = substitutions[variable] {
				localSubstitutions[variable] = type
			} else {
				let newVar: InferenceResult = .type(
					.typeVar(
						freshTypeVariable(variable.name ?? "<unnamed>")
					)
				)

				localSubstitutions[variable] = newVar
			}
		}

		return applySubstitutions(to: .type(scheme.type), with: localSubstitutions)
	}

	func log(_ msg: String, prefix: String, context: InferenceContext? = nil) {
		if verbose {
			var depth = 0
			var nextParent = self.parent
			while let parent = nextParent {
				depth += 1
				nextParent = parent.parent
			}

			print("\(depth) \(String(repeating: "\t", count: max(0, depth - 1)))" + prefix + msg)
		}
	}
}
