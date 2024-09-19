//
//  InferenceType+Descriptions.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/18/24.
//

extension InferenceType: CustomStringConvertible, CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
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

	public var description: String {
		switch self {
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
