//
//  InferenceType+Descriptions.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/18/24.
//

extension InferenceType: CustomDebugStringConvertible {
	public var mangled: String {
		switch self {
		case .typeVar:
			"T"
		case .base(let primitive):
			primitive.description
		case .function(let params, let returns):
			params.map { $0.asType?.mangled ?? "" }.joined(separator: "_") + (returns.asType?.mangled ?? "")
		case .instance(let instanceType):
			"I" + instanceType.type.name
		case .instantiatable(let instantiatableType):
			instantiatableType.name + instantiatableType.typeContext.typeParameters.map { $0.name ?? "_" }.joined(separator: "_")
		case .placeholder(let typeVariable):
			"P\(typeVariable.name ?? "")"
		case .instancePlaceholder(let typeVariable):
			"IP\(typeVariable.name ?? "")"
		case .error(let inferenceError):
			"ERROR: \(inferenceError.description)"
		case .kind(let inferenceType):
			"K(\(inferenceType.mangled)"
		case .selfVar:
			"self"
		case .enumCase(let enumCase):
			enumCase.name
		case .pattern(let pattern):
			pattern.type.mangled
		case .any:
			"any"
		case .void:
			"void"
		}
	}

	public var debugDescription: String {
		switch self {
		case let .instancePlaceholder(typeVar):
			"instance placeholder \(typeVar.debugDescription)"
		case let .instance(instance):
			"\(instance.debugDescription)"
		case let .typeVar(typeVariable):
			typeVariable.debugDescription
		case let .base(primitive):
			"\(primitive)"
		case let .function(vars, inferenceType):
			"function(\(vars.map(\.debugDescription).joined(separator: ", "))), returns(\(inferenceType.debugDescription))"
		case let .error(error):
			"error(\(error))"
		case let .instantiatable(type):
			type.name + ".Type"
		case let .kind(type):
			"\(type.debugDescription).Kind"
		case .any:
			"any"
		case let .selfVar(type):
			"\(type) (self)"
		case let .placeholder(variable):
			"\(variable) (placeholder)"
		case let .enumCase(kase):
			kase.description
		case let .pattern(pattern):
			"pattern: \(pattern)"
		case .void:
			"void"
		}
	}

	internal var description: String {
		switch self {
		case let .instancePlaceholder(typeVar):
			"instance placeholder \(typeVar)"
		case let .instance(instance):
			"\(instance.description)"
		case let .typeVar(typeVariable):
			typeVariable.description
		case let .base(primitive):
			"\(primitive)"
		case let .function(vars, inferenceType):
			"function(\(vars.map(\.description).joined(separator: ", "))), returns(\(inferenceType))"
		case let .error(error):
			"error(\(error))"
		case let .instantiatable(type):
			type.name + ".Type"
		case let .kind(type):
			"\(type).Kind"
		case .any:
			"any"
		case let .selfVar(type):
			"\(type) (self)"
		case let .placeholder(variable):
			"\(variable) (placeholder)"
		case let .enumCase(kase):
			kase.description
		case let .pattern(pattern):
			"pattern: \(pattern)"
		case .void:
			"void"
		}
	}
}
