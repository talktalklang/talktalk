//
//  Mangler.swift
//  
//
//  Created by Pat Nakajima on 7/23/24.
//

public struct Mangler {
	static func mangle(function name: String, parameters: ParameterList, scope: Scope) -> String {
		return name

		// Start with something that's unlikely to be confused
		var parts = ["_F$d\(scope.depth)"]

		// Add the name, seems chill
		parts.append(name)

		// Indicate start of parameter list with a count
		parts.append("$P\(parameters.list.count)")

		for parameter in parameters.list {
			parts.append("_")
			parts.append("\((parameter.name + parameter.binding.type.description).count)")
			parts.append(parameter.name)
			parts.append(parameter.binding.type.description)
		}

		return parts.joined()
	}
}
