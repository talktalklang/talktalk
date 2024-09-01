//
//  Context.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import Foundation
import TalkTalkSyntax
import OrderedCollections

typealias VariableID = Int

public enum InferenceErrorKind: Equatable, Hashable {
	case undefinedVariable(String)
	case unknownError(String)
	case constraintError(String)
	case argumentError(expected: Int, actual: Int)
	case typeError(String)
	case memberNotFound(StructType, String)
	case missingConstraint(InferenceType)
	case subscriptNotAllowed(InferenceType)
}

public struct InferenceError: Hashable, Equatable {
	public let kind: InferenceErrorKind
	public let location: SourceLocation

	public init(kind: InferenceErrorKind, location: SourceLocation) {
		self.kind = kind
		self.location = location
	}
}

// If we're inside a type's body, we can save methods/properties in here
class TypeContext {
	var methods: OrderedDictionary<String, InferenceResult>
	var initializers: OrderedDictionary<String, InferenceResult>
	var properties: OrderedDictionary<String, InferenceResult>
	var typeParameters: [TypeVariable]

	init(
		methods: OrderedDictionary<String, InferenceResult> = [:],
		initializers: OrderedDictionary<String, InferenceResult> = [:],
		properties: OrderedDictionary<String, InferenceResult> = [:],
		typeParameters: [TypeVariable] = []
	) {
		self.methods = methods
		self.initializers = initializers
		self.properties = properties
		self.typeParameters = typeParameters
	}
}

class InstanceContext: CustomDebugStringConvertible {
	var substitutions: [TypeVariable: InferenceType] = [:]

	var debugDescription: String {
		"InstanceContext(\(substitutions))"
	}

	func wrapped(_ typeVariable: TypeVariable) -> InferenceType {
		if let wrapped = substitutions[typeVariable] {
			return wrapped
		}

		let variable = TypeVariable("instance \(typeVariable)", substitutions.count)
		substitutions[typeVariable] = .typeVar(variable)
		return .typeVar(variable)
	}
}

public class InferenceContext: CustomDebugStringConvertible {
	var environment: Environment
	var parent: InferenceContext?
	var imports: [InferenceContext]
	let depth: Int
	public var errors: [InferenceError] = []
	var constraints: Constraints
	var substitutions: [TypeVariable: InferenceType] = [:]
	private(set) public var namedVariables: [String: InferenceType] = [:]
	private(set) var namedPlaceholders: [String: InferenceType] = [:]
	var nextID: VariableID = 0
	var verbose: Bool = false
	private var namedCounters: [String: Int] = [:]

	// Type-level context info like methods, properties, etc
	var typeContext: TypeContext?

	// Instance-level context info like generic parameter bindings
	var instanceContext: InstanceContext?

	init(
		parent: InferenceContext?,
		imports: [InferenceContext] = [],
		environment: Environment,
		constraints: Constraints,
		substitutions: [TypeVariable: InferenceType] = [:],
		typeContext: TypeContext? = nil,
		instanceContext: InstanceContext? = nil
	) {
		self.depth = (parent?.depth ?? 0) + 1
		self.parent = parent
		self.imports = imports
		self.environment = environment
		self.constraints = constraints
		self.substitutions = substitutions
		self.typeContext = typeContext
		self.instanceContext = instanceContext

		log("New context with depth \(depth)", prefix: " * ")
	}

	public func lookup(syntax: any Syntax) -> InferenceType? {
		let result = self[syntax]?.asType(in: self)

		if case let .placeholder(typeVariable) = result {
			return .error(.init(kind: .undefinedVariable(typeVariable.name ?? "<none>"), location: syntax.location))
		}

		return result
	}

	func definePlaceholder(named name: String, as type: InferenceType, at location: SourceLocation) {
		if let parent {
			parent.definePlaceholder(named: name, as: type, at: location)
			return
		}

		namedPlaceholders[name] = type
	}

	func lookupPlaceholder(named name: String) -> InferenceType? {
		if let parent {
			return parent.lookupPlaceholder(named: name)
		}

		return namedPlaceholders[name]
	}

	func defineVariable(named name: String, as type: InferenceType, at location: SourceLocation) {
		if case let .placeholder(typeVar) = lookupPlaceholder(named: name) {
			log("Adding equality constraint for placeholder \(name)", prefix: " = ")
			addConstraint(.equality(type, .placeholder(typeVar), at: location))
		}

		namedVariables[name] = type
	}

	func lookupVariable(named name: String) -> InferenceType? {
		if let result = namedVariables[name] {
			return result
		}

		if let result = parent?.lookupVariable(named: name) {
			return result
		}

		if let builtin = BuiltinFunction.list.first(where: { $0.name == name }) {
			return builtin.type
		}

		for imported in imports {
			if let result = imported.lookupVariable(named: name) {
				return result
			}
		}

		return nil
	}

	public func `import`(_ context: InferenceContext) {
		imports.append(context)
	}

	func constraintExists(forTypeVar typeVar: TypeVariable) -> Bool {
		if let parent {
			return parent.constraintExists(forTypeVar: typeVar)
		}

		return constraints.exists(forTypeVar: typeVar)
	}

	func constraintExists<T: Constraint>(for type: T.Type, where block: (T) -> Bool) -> Bool {
		if let parent {
			return parent.constraintExists(for: type, where: block)
		}

		return constraints.exists(for: type, where: block)
	}

	func addConstraint(_ constraint: any Constraint) {
		if let parent {
			parent.addConstraint(constraint)
			return
		}

		constraints.add(constraint)
	}

	func deferConstraint(_ constraint: any Constraint) {
		if let parent {
			parent.deferConstraint(constraint)
			return
		}

		constraints.defer(constraint)
	}

	func nextIdentifier(named name: String) -> Int {
		if let parent {
			return parent.nextIdentifier(named: name)
		}

		defer { namedCounters[name, default: 0] += 1 }
		return namedCounters[name, default: 0]
	}

	public var debugDescription: String {
		var result = "InferenceContext parent: \(parent == nil ? "none" : "<\(parent?.namedVariables.description ?? "")>")"
		result += "Environment:\n"

		for (key, val) in environment.types {
			result += "- syntax id \(key) : \(val.description)\n"
		}

		return result
	}

	func childContext() -> InferenceContext {
		InferenceContext(
			parent: self,
			environment: environment.childEnvironment(),
			constraints: constraints,
			substitutions: substitutions,
			typeContext: typeContext
		)
	}

	func childInstanceContext(withSelf: TypeVariable) -> InferenceContext {
		assert(instanceContext == nil, "trying to instantiate an instance context when we're already in one")
		assert(typeContext != nil, "trying to instantiate an instance context without type")

		let instanceContext = InstanceContext()

		return InferenceContext(
			parent: self,
			environment: environment,
			constraints: constraints,
			substitutions: substitutions,
			typeContext: typeContext!,
			instanceContext: instanceContext
		)
	}

	func childTypeContext() -> InferenceContext {
		InferenceContext(
			parent: self,
			environment: environment,
			constraints: constraints,
			substitutions: substitutions,
			typeContext: typeContext ?? TypeContext()
		)
	}

	func lookupType(named name: String) -> InferenceType? {
		switch name {
		case "int":
			return .base(.int)
		case "String":
			return .base(.string)
		case "bool":
			return .base(.bool)
		case "pointer":
			return .base(.pointer)
		default:
			return nil
		}
	}

	func lookupTypeContext() -> TypeContext? {
		if let typeContext {
			return typeContext
		}

		return parent?.typeContext
	}

	func solve() -> InferenceContext {
		var solver = Solver(context: self)
		return solver.solve()
	}

	func solveDeferred() -> InferenceContext {
		var solver = Solver(context: self)
		return solver.solveDeferred()
	}

	@discardableResult func addError(_ inferrenceError: InferenceErrorKind, to expr: any Syntax) -> InferenceType {
		if let parent {
			return parent.addError(inferrenceError, to: expr)
		}

		let error = InferenceError(kind: inferrenceError, location: expr.location)
		errors.append(error)
		environment.extend(expr, with: .type(.error(error)))
		return .error(error)
	}

	func extend(_ syntax: any Syntax, with result: InferenceResult) {
		environment.extend(syntax, with: result)

		parent?.extend(syntax, with: result)
	}

	func isFreeVariable(_ type: InferenceType) -> Bool {
		if case let .typeVar(variable) = type {
			// Check if the variable already has constraints assigned to it. If so
			// then it's not free.
			if constraintExists(forTypeVar: variable) {
				return false
			}

			// Check if the variable exists in the context's substitution map
			// If it's not in the substitution map, it's a free variable
			return substitutions[variable] == nil
		}

		return false
	}

	func trackReturns(_ block: () throws -> Void) throws -> Set<InferenceResult> {
		try environment.trackingReturns(block: block)
	}

	func trackReturn(_ result: InferenceResult) {
		environment.trackReturn(result)
	}

	func lookupSubstitution(named name: String) -> InferenceType? {
		substitutions.first(where: { variable, _ in variable.name == name })?.value
	}

	// Look up inference results for a particular syntax node
	subscript(syntax: any Syntax) -> InferenceResult? {
		get {
			switch environment[syntax] ?? parent?[syntax] {
			case let .scheme(scheme): return .scheme(scheme)
			case let .type(type): return .type(applySubstitutions(to: type))
			default:
				return nil
			}
		}

		set {
			environment[syntax] = newValue
		}
	}

	@discardableResult func addError(_ inferenceError: InferenceError) -> InferenceType {
		if let parent {
			return parent.addError(inferenceError)
		}

		errors.append(inferenceError)
		return .error(inferenceError)
	}

	func generateID() -> Int {
		if let parent {
			return parent.generateID()
		}

		defer { nextID += 1 }
		return nextID
	}

	func freshTypeVariable(_ name: String, creatingContext: InferenceContext? = nil, file: String = #file, line: UInt32 = #line) -> TypeVariable {
		if let parent {
			return parent.freshTypeVariable(name, creatingContext: creatingContext ?? self, file: file, line: line)
		}

		let typeVariable = TypeVariable(name, generateID())

		log("New type variable: \(typeVariable), \(file):\(line)", prefix: " + ", context: creatingContext ?? self)

		return typeVariable
	}

	// A helper just because we so frequently just want an inference type when getting a new variable
	func freshTypeVariable(_ name: String, creatingContext: InferenceContext? = nil, file: String, line: UInt32) -> InferenceType {
		.typeVar(freshTypeVariable(name, creatingContext: creatingContext, file: file, line: line))
	}

	func bind(typeVar: TypeVariable, to type: InferenceType) {
		guard .typeVar(typeVar) != type else {
			fatalError("cannot bind type var to itself")
		}

		substitutions[typeVar] = type
	}

	func applySubstitutions(
		to type: InferenceType,
		with substitutions: [TypeVariable: InferenceType],
		count: Int = 0
	) -> InferenceType {
		if substitutions.isEmpty {
			return type
		}

		switch type {
		case let .typeVar(typeVariable), let .placeholder(typeVariable):
			// Reach down recursively as long as we can to try to find the result
			if case let .typeVar(child) = substitutions[typeVariable], count < 100 {
				return applySubstitutions(to: .typeVar(child), with: substitutions, count: count + 1)
			}

			return substitutions[typeVariable] ?? type
		case let .function(params, returning):
			return .function(params.map { applySubstitutions(to: $0, with: substitutions) }, applySubstitutions(to: returning, with: substitutions))
		case let .structInstance(instance):
//			for case let (key, .typeVar(val)) in substitutions {
//				if instance.substitutions[val] != nil {
//					instance.substitutions[val] = .typeVar(key)
//				}
//			}

			// Help here:
			return .structInstance(instance)
		default:
			return type // Base/error/void types don't get substitutions
		}
	}

	func applySubstitutions(to type: InferenceType, withParents: Bool = false) -> InferenceType {
		let parentResult = parent?.applySubstitutions(to: type) ?? type
		return applySubstitutions(to: parentResult, with: substitutions)
	}

	func applySubstitutions(to result: InferenceResult, withParents: Bool = false) -> InferenceType {
		return applySubstitutions(to: result.asType(in: self))
	}

	func applySubstitutions(to result: InferenceResult, with: [TypeVariable: InferenceType]) -> InferenceType {
		return applySubstitutions(to: result.asType(in: self), with: with)
	}

	// See if these types are compatible. If so, bind 'em.
	func unify(_ typeA: InferenceType, _ typeB: InferenceType, _ location: SourceLocation) {
		let a = applySubstitutions(to: typeA)
		let b = applySubstitutions(to: typeB)

		log("Unifying \(typeA) <-> \(typeB)", prefix: " & ")

		switch (a, b) {
		case let (.base(a), .base(b)) where a != b:
			log("Cannot unify \(a) and \(b)", prefix: " ! ")
			addError(
				.init(
					kind: .typeError("Cannot unify \(a) and \(b)"),
					location: location
				)
			)
		case let (.base(_), .typeVar(b)):
			bind(typeVar: b, to: a)
			log("Got a base type: \(a)", prefix: " ' ")
		case let (.typeVar(a), .base(_)):
			bind(typeVar: a, to: b)
			log("Got a base type: \(b)", prefix: " ' ")
		case let (.typeVar(v), _) where .typeVar(v) != b:
			bind(typeVar: v, to: b)
		case let (_, .typeVar(v)) where .typeVar(v) != a:
			bind(typeVar: v, to: a)
		case let (.placeholder(v), _) where .placeholder(v) != b:
			bind(typeVar: v, to: b)
		case let (_, .placeholder(v)) where .placeholder(v) != a:
			bind(typeVar: v, to: a)
		case let (.function(paramsA, returnA), .function(paramsB, returnB)):
			zip(paramsA, paramsB).forEach { unify($0, $1, location) }
			unify(returnA, returnB, location)
		case let (.kind(.typeVar(a)), .kind(b)):
			bind(typeVar: a, to: b)
		case let (.kind(a), .kind(.typeVar(b))):
			bind(typeVar: b, to: a)
		case let (.structType(a), .structType(b)) where a.name == b.name:
			// Unify struct type parameters if needed
			break
		case let (.structInstance(a), .structInstance(b)) where a.type.name == b.type.name:
			// Unify struct instance type parameters if needed
			for (subA, subB) in zip(a.substitutions, b.substitutions) {
				unify(subA.value, subB.value, location)
			}
		default:
			if a != b, a != .any, b != .any {
				addError(
					.init(
						kind: .typeError("Cannot unify \(a) and \(b)"),
						location: location
					)
				)
			}
//			addError(.typeError("Cannot unify \(a) and \(b)"))
		}
	}

	// Turn this scheme into an actual type, using whatever environment we
	// have at this moment
	func instantiate(scheme: Scheme) -> InferenceType {
		var localSubstitutions: [TypeVariable: InferenceType] = [:]

		// Replace the scheme's variables with fresh type variables
		for case let .typeVar(variable) in scheme.variables {
			localSubstitutions[variable] = substitutions[variable] ?? .typeVar(freshTypeVariable((variable.name ?? "<unnamed>") + " [scheme]", file: #file, line: #line))
		}

		return applySubstitutions(to: scheme.type, with: substitutions.merging(localSubstitutions, uniquingKeysWith: { $1 }))
	}

	func log(_ msg: String, prefix: String, context: InferenceContext? = nil) {
		if verbose {
			let context = context ?? self
			print("\(context.depth) " + prefix + msg)
		}
	}
}
