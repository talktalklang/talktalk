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
			params.map { $0.mangled }.joined(separator: "_") + returns.mangled
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
		case let .pattern(pattern):
			"\(pattern)"
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
			"self (\(type.debugDescription))"
		case .instance(let instance):
			instance.debugDescription
		case let .instancePlaceholder(typeVar):
			"instance placeholder \(typeVar.debugDescription)"
		case let .typeVar(typeVariable):
			typeVariable.debugDescription
		case let .base(primitive):
			"\(primitive)"
		case let .function(vars, inferenceType):
			"function(\(vars.map(\.debugDescription).joined(separator: ", "))), returns(\(inferenceType.debugDescription))"
		case let .error(error):
			"error(\(error))"
		case let .kind(type):
			"\(type.debugDescription).Kind"
		case .any:
			"any"
		case let .selfVar(type):
			"\(type) (self)"
		case let .placeholder(variable):
			"\(variable.debugDescription) (placeholder)"
		case let .pattern(pattern):
			"\(pattern)"
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
		case let .typeVar(typeVariable):
			typeVariable.description
		case let .base(primitive):
			"\(primitive)"
		case let .function(vars, inferenceType):
			"function(\(vars.map(\.description).joined(separator: ", "))), returns(\(inferenceType))"
		case let .error(error):
			"error(\(error))"
		case let .kind(type):
			"\(type).Kind"
		case .any:
			"any"
		case let .selfVar(type):
			"\(type) (self)"
		case let .placeholder(variable):
			"\(variable) (placeholder)"
		case let .pattern(pattern):
			"\(pattern)"
		case .void:
			"void"
		case let .type(type):
			"\(type)"
		}
	}
}
