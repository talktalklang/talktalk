//
//  AnalysisModule+Completions.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/17/24.
//

import TalkTalkCore

public struct Completion: Sendable {
	public enum Trigger: Sendable {
		case character(String)
	}

	public struct Request: Sendable {
		public let documentURI: String
		public let line: Int
		public let column: Int
		public let trigger: Trigger?

		public init(
			documentURI: String,
			line: Int,
			column: Int,
			trigger: Trigger? = nil
		) {
			self.documentURI = documentURI
			self.line = line
			self.column = column
			self.trigger = trigger
		}
	}

	public enum Kind: Equatable, Sendable {
		case variable, method, function, type, property
	}

	public struct Item: Equatable, Sendable, Comparable, Hashable {
		public static func < (lhs: Completion.Item, rhs: Completion.Item) -> Bool {
			lhs.value < rhs.value
		}

		public let kind: Kind
		public let value: String

		public init(value: String, kind: Kind) {
			self.kind = kind
			self.value = value
		}
	}
}

public extension AnalysisModule {
	func completions(for request: Completion.Request) -> Set<Completion.Item> {
		if case .character(".") = request.trigger {
			return dotCompletions(for: request)
		}

		return freeCompletions(for: request)
	}

	private func matching(
		line: Int,
		column: Int,
		exprs: [any AnalyzedSyntax]
	) -> [any AnalyzedSyntax] {
		var result: [any AnalyzedSyntax] = []
		for expr in exprs {
			if expr.location.contains(line: line, column: column) {
				result.append(expr)
			}

			result.append(
				contentsOf: matching(
					line: line,
					column: column,
					exprs: expr.analyzedChildren
				)
			)
		}

		return result
	}

	private func dotCompletions(for request: Completion.Request) -> Set<Completion.Item> {
		var result: Set<Completion.Item> = []
		let matches = matching(
			line: request.line,
			column: request.column,
			exprs: analyzedFiles.first(where: { $0.path == request.documentURI })?.syntax ?? []
		)

		// Try to figure out the receiver of the member access
		for match in matches {
			guard let match = match as? AnalyzedExprStmt,
			      let memberExpr = match.exprAnalyzed as? AnalyzedMemberExpr,
			      case let .instance(instance) = memberExpr.receiverAnalyzed.inferenceType
			else {
				continue
			}

			for prop in instance.members.keys {
				if prop.starts(with: memberExpr.property), !prop.starts(with: "_") {
					result.insert(.init(value: prop, kind: .property))
				}
			}
		}

		return result
	}

	// If there's not a dot, then we just look for anything that could go here.
	private func freeCompletions(for request: Completion.Request) -> Set<Completion.Item> {
		var result: Set<Completion.Item> = []
		let matches = matching(
			line: request.line,
			column: request.column,
			exprs: analyzedFiles.first(where: { $0.path == request.documentURI })?.syntax ?? []
		)

		for match in matches {
			if let match = match as? AnalyzedVarExpr {
				let name = match.name

				for (structName, _) in structs {
					if structName.starts(with: name) {
						result.insert(Completion.Item(value: structName, kind: .type))
					}
				}

				for binding in match.environment.allBindings() {
					if binding.name.starts(with: name) {
						let kind: Completion.Kind = switch binding.type {
						case .function:
							.function
						case .type:
							.type
						default:
							.variable
						}

						result.insert(Completion.Item(value: binding.name, kind: kind))
					}
				}
			}
		}

		return result
	}
}
