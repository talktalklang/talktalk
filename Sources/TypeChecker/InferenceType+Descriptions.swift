//
//  InferenceType+Descriptions.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/18/24.
//

extension InferenceType: CustomDebugStringConvertible {
	public var mangled: String {
		switch self {
		case .self:
			"self"
		case .instance(let instance):
			"I\(instance.type.name)"
		case .typeVar:
			"T"
		case let .base(primitive):
			primitive.description
		case let .function(params, returns):
			params.map { $0.asType?.mangled ?? "" }.joined(separator: "_") + (returns.asType?.mangled ?? "")
		case let .instanceV1(instanceType):
			"I" + instanceType.type.name
		case let .instantiatable(instantiatableType):
			instantiatableType.name + instantiatableType.typeContext.typeParameters.map { $0.name ?? "_" }.joined(separator: "_")
		case let .placeholder(typeVariable):
			"P\(typeVariable.name ?? "")"
		case let .instancePlaceholder(typeVariable):
			"IP\(typeVariable.name ?? "")"
		case let .error(inferenceError):
			"ERROR: \(inferenceError.description)"
		case let .kind(inferenceType):
			"K(\(inferenceType.mangled)"
		case .selfVar:
			"self"
		case let .enumCaseV1(enumCase):
			enumCase.name
		case let .pattern(pattern):
			pattern.type.mangled
		case .any:
			"any"
		case .void:
			"void"
		case let .type(type):
			"\(type)"
		}
	}

	public var debugDescription: String {
		switch self {
		case .self(let type):
			"self (\(type))"
		case .instance(let instance):
			"Instance \(instance.type.name)"
		case let .instancePlaceholder(typeVar):
			"instance placeholder \(typeVar.debugDescription)"
		case let .instanceV1(instance):
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
			"\(variable.debugDescription) (placeholder)"
		case let .enumCaseV1(kase):
			kase.description
		case let .pattern(pattern):
			"pattern: \(pattern)"
		case .void:
			"void"
		case let .type(type):
			"\(type)"
		}
	}

	var description: String {
		switch self {
		case .self:
			"self"
		case .instance(let instance):
			"Instance \(instance.type.name)"
		case let .instancePlaceholder(typeVar):
			"instance placeholder \(typeVar)"
		case let .instanceV1(instance):
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
		case let .enumCaseV1(kase):
			kase.description
		case let .pattern(pattern):
			"pattern: \(pattern)"
		case .void:
			"void"
		case let .type(type):
			"\(type)"
		}
	}
}
