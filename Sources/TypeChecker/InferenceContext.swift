//
//  InferenceContext.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/25/24.
//

import Foundation
import OrderedCollections
import TalkTalkSyntax

typealias VariableID = Int

// If we're inside a type's body, we can save methods/properties in here
public class TypeContext: Equatable, Hashable {
	public static func ==(lhs: TypeContext, rhs: TypeContext) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	public var name: String
	var methods: OrderedDictionary<String, InferenceResult>
	var initializers: OrderedDictionary<String, InferenceResult>
	var properties: OrderedDictionary<String, InferenceResult>
	var typeParameters: [TypeVariable]

	init(
		name: String,
		methods: OrderedDictionary<String, InferenceResult> = [:],
		initializers: OrderedDictionary<String, InferenceResult> = [:],
		properties: OrderedDictionary<String, InferenceResult> = [:],
		typeParameters: [TypeVariable] = []
	) {
		self.name = name
		self.methods = methods
		self.initializers = initializers
		self.properties = properties
		self.typeParameters = typeParameters
	}

	public func member(named name: String) -> InferenceResult? {
		methods[name] ?? properties[name] ?? initializers[name]
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(methods.keys)
		hasher.combine(initializers)
		hasher.combine(properties)
		hasher.combine(typeParameters)
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

class MatchContext {
	let target: InferenceType
	var current: any Syntax
	var substitutions: [TypeVariable: InferenceType] = [:]

	init(target: InferenceType, current: any Syntax) {
		self.target = target
		self.current = current
	}
}

public class InferenceContext: CustomDebugStringConvertible {
	// Stores the mappings of syntax nodes to inference types
	var environment: Environment

	// Names that we know at inference time
	public private(set) var namedVariables: [String: InferenceType] = [:]

	// Names that we're going to have to solve for later
	private(set) var namedPlaceholders: [String: InferenceType] = [:]

	// Does this context have a parent?
	var parent: InferenceContext?

	// Makes info from other contexts available
	var imports: [InferenceContext]

	// How many parents does this context have
	let depth: Int

	// Errors that occur
	public var errors: [InferenceError] = []

	// The list of constraints to solve
	var constraints: Constraints

	// Known substitutions due to unification
	var substitutions: [TypeVariable: InferenceType] = [:]

	// Gives subexpressions a hint about what type they're expected to be.
	var expectation: InferenceType?

	// For fresh variable generation
	var nextID: VariableID = 0

	// Used for generating specific IDs, like for struct instances
	private var namedCounters: [String: Int] = [:]

	// Should we be logging?
	var verbose: Bool = false

	// Type-level context info like methods, properties, etc
	public var typeContext: TypeContext?

	// Match target context, used for match statements
	var matchContext: MatchContext?

	// Instance-level context info like generic parameter bindings
	var instanceContext: InstanceContext?

	init(
		parent: InferenceContext?,
		imports: [InferenceContext] = [],
		environment: Environment,
		constraints: Constraints,
		substitutions: [TypeVariable: InferenceType] = [:],
		typeContext: TypeContext? = nil,
		instanceContext: InstanceContext? = nil,
		expectation: InferenceType? = nil,
		matchContext: MatchContext? = nil
	) {
		self.depth = (parent?.depth ?? 0) + 1
		self.parent = parent
		self.imports = imports
		self.environment = environment
		self.constraints = constraints
		self.substitutions = substitutions
		self.typeContext = typeContext
		self.instanceContext = instanceContext
		self.expectation = expectation
		self.matchContext = matchContext

		log("New context with depth \(depth)", prefix: " * ")
	}

	public func exists(syntax: any Syntax) -> Bool {
		self[syntax] != nil
	}

	public func lookup(syntax: any Syntax) -> InferenceType? {
		guard let result = self[syntax]?.asType(in: self) else {
			return .error(.init(kind: .unknownError("no type found for: \(syntax.description)"), location: syntax.location))
		}

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
			typeContext: typeContext,
			expectation: expectation,
			matchContext: matchContext
		)
	}

	func withMatchContext(_ matchContext: MatchContext) -> InferenceContext {
		InferenceContext(
			parent: self,
			environment: environment.childEnvironment(),
			constraints: constraints,
			substitutions: substitutions,
			typeContext: typeContext,
			matchContext: matchContext
		)
	}

	func childInstanceContext(withSelf _: TypeVariable) -> InferenceContext {
		assert(instanceContext == nil, "trying to instantiate an instance context when we're already in one")
		guard let typeContext else {
			// swiftlint:disable fatal_error
			fatalError("trying to instantiate an instance context without type")
			// swiftlint:enable fatal_error
		}

		let instanceContext = InstanceContext()

		return InferenceContext(
			parent: self,
			environment: environment,
			constraints: constraints,
			substitutions: substitutions,
			typeContext: typeContext,
			instanceContext: instanceContext,
			expectation: expectation,
			matchContext: matchContext
		)
	}

	func childTypeContext(named name: String) -> InferenceContext {
		InferenceContext(
			parent: self,
			environment: environment,
			constraints: constraints,
			substitutions: substitutions,
			typeContext: typeContext ?? TypeContext(name: name),
			expectation: expectation,
			matchContext: matchContext
		)
	}

	func expecting(_ type: InferenceType) -> InferenceContext {
		InferenceContext(
			parent: self,
			environment: environment,
			constraints: constraints,
			substitutions: substitutions,
			typeContext: typeContext ?? TypeContext(name: type.description),
			expectation: type,
			matchContext: matchContext
		)
	}

	func lookupPrimitive(named name: String) -> InferenceType? {
		switch name {
		case "int":
			.base(.int)
		case "String":
			.base(.string)
		case "bool":
			.base(.bool)
		case "pointer":
			.base(.pointer)
		default:
			nil
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

	func trackReturns(_ block: () throws -> Void) throws -> [InferenceResult] {
		try environment.trackingReturns(block: block)
	}

	func trackReturn(_ result: InferenceResult) {
		environment.trackReturn(result)
	}

	func lookupSubstitution(named name: String) -> InferenceType? {
		substitutions.first(where: { variable, _ in variable.name == name })?.value
	}

	func get(_ syntax: any Syntax) throws -> InferenceResult {
		guard let result = self[syntax] else {
			throw InferencerError.typeNotInferred("Expected inferred type for \(syntax)")
		}

		return result
	}

	// Look up inference results for a particular syntax node
	subscript(syntax: any Syntax) -> InferenceResult? {
		get {
			switch environment[syntax] ?? parent?[syntax] {
			case let .scheme(scheme): .scheme(scheme)
			case let .type(type): .type(applySubstitutions(to: type))
			default:
				nil
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

		log("New type variable: \(typeVariable.debugDescription), \(file):\(line)", prefix: " + ", context: creatingContext ?? self)

		return typeVariable
	}

	// A helper just because we so frequently just want an inference type when getting a new variable
	func freshTypeVariable(_ name: String, creatingContext: InferenceContext? = nil, file: String, line: UInt32) -> InferenceType {
		.typeVar(freshTypeVariable(name, creatingContext: creatingContext, file: file, line: line))
	}

	func bind(typeVar: TypeVariable, to type: InferenceType) {
		guard .typeVar(typeVar) != type else {
			print("cannot bind type var to itself")
			return
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
		case let .pattern(pattern):
			return .pattern(
				Pattern(
					type: applySubstitutions(to: pattern.type, with: substitutions),
					arguments: pattern.arguments.map {
						switch $0 {
						case let .value(type):
							.value(applySubstitutions(to: type, with: substitutions))
						case let .variable(name, type):
							.variable(name, applySubstitutions(to: type, with: substitutions))
						}
					}
				)
			)
		case let .typeVar(typeVariable), let .placeholder(typeVariable):
			// Reach down recursively as long as we can to try to find the result
			if case let .typeVar(child) = substitutions[typeVariable], count < 100 {
				return applySubstitutions(to: .typeVar(child), with: substitutions, count: count + 1)
			}

			return substitutions[typeVariable] ?? type
		case let .function(params, returning):
			return .function(
				params.map { applySubstitutions(to: $0, with: substitutions) },
				applySubstitutions(to: returning, with: substitutions)
			)
		case let .structInstance(instance):
			return .structInstance(instance)
		case let .enumType(type):
			return .enumType(EnumType(
				name: type.name,
				cases: type.cases.map {
					// swiftlint:disable force_unwrapping
					EnumCase.extract(from: .type(applySubstitutions(to: .enumCase($0), with: substitutions)))!
					// swiftlint:enable force_unwrapping
				},
				typeContext: type.typeContext
			))
		case let .enumCase(kase):
			return .enumCase(
				EnumCase(
					typeName: kase.typeName,
					name: kase.name,
					index: kase.index,
					attachedTypes: kase.attachedTypes.map { applySubstitutions(to: $0, with: substitutions) }
				)
			)
		default:
			return type // Base/error/void types don't get substitutions
		}
	}

	func applySubstitutions(to type: InferenceType, withParents _: Bool = false) -> InferenceType {
		let parentResult = parent?.applySubstitutions(to: type) ?? type
		return applySubstitutions(to: parentResult, with: substitutions)
	}

	func applySubstitutions(to result: InferenceResult, withParents _: Bool = false) -> InferenceType {
		applySubstitutions(to: result.asType(in: self))
	}

	func applySubstitutions(to result: InferenceResult, with: [TypeVariable: InferenceType]) -> InferenceType {
		applySubstitutions(to: result.asType(in: self), with: with)
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
					kind: .unificationError(typeA, typeB),
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
		case let (.enumType(type), .enumCase(kase)):
			if type.name != kase.typeName {
				addError(
					.init(
						kind: .unificationError(typeA, typeB),
						location: location
					)
				)
			}
		case let (.enumCase(kase), .enumType(type)):
			if type.name != kase.typeName {
				addError(
					.init(
						kind: .unificationError(typeA, typeB),
						location: location
					)
				)
			}
		case let (.boxedInstance(boxed), .structInstance(instance)):
			()
		case let (.structInstance(instance), .boxedInstance(boxed)):
			()
		default:
			if a != b, a != .any, b != .any {
				addError(
					.init(
						kind: .unificationError(typeA, typeB),
						location: location
					)
				)
			}
		}
	}

	// Turn this scheme into an actual type, using whatever environment we
	// have at this moment
	func instantiate(scheme: Scheme) -> InferenceType {
		var localSubstitutions: [TypeVariable: InferenceType] = [:]

		// Replace the scheme's variables with fresh type variables
		for case let .typeVar(variable) in scheme.variables {
			localSubstitutions[variable] = substitutions[variable] ?? .typeVar(
				freshTypeVariable(
					variable.name ?? "<unnamed>",
					file: #file,
					line: #line
				)
			)
		}

		return applySubstitutions(
			to: scheme.type,
			with: substitutions.merging(localSubstitutions, uniquingKeysWith: { $1 })
		)
	}

	func log(_ msg: String, prefix: String, context: InferenceContext? = nil) {
		if verbose {
			let context = context ?? self
			print("\(context.depth) " + prefix + msg)
		}
	}
}
