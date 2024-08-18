//
//  Printer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/16/24.
//

import Foundation
import TalkTalkSyntax

@resultBuilder struct StringBuilder {
	static func buildBlock(_ strings: String...) -> String {
		strings.joined(separator: "\n")
	}

	static func buildOptional(_ component: String?) -> String {
		component ?? ""
	}

	static func buildEither(first component: String) -> String {
		component
	}

	static func buildEither(second component: String) -> String {
		component
	}

	static func buildArray(_ components: [String]) -> String {
		components.joined(separator: "\n")
	}
}

public struct AnalysisPrinter: AnalyzedVisitor {
	var indentLevel: Int = 0

	public init() {}

	public static func format(_ syntax: [any AnalyzedSyntax]) throws -> String {
		let formatter = AnalysisPrinter()
		let result = try syntax.map { try $0.accept(formatter, ()) }
		return result.map { line in
			line.replacing(
				#/(\t+)(\d+) │ /#,
				with: {
					// Tidy indents
					"\($0.output.2) |\($0.output.1)└ "
				}
			).replacing(
				#/(\t*)(\d+)[\s]*\|/#,
				with: {
					// Tidy line numbers
					$0.output.2.trimmingCharacters(in: .whitespacesAndNewlines).padding(
						toLength: 4, withPad: " ", startingAt: 0
					) + "| \($0.output.1)"
				}
			)

		}.joined(separator: "\n")
	}

	func dump(_ expr: any AnalyzedSyntax, _ extra: String = "") -> String {
		"\(expr.location.start.line) | \(type(of: expr)) -> \(expr.typeID.current.description) \(expr.location.start.column)..<\(expr.location.end.column) \(expr.description.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") \(extra)"
	}

	func add(@StringBuilder _ content: () throws -> String) -> String {
		try! content()
			.components(separatedBy: .newlines)
			.filter { $0.trimmingCharacters(in: .whitespacesAndNewlines) != "" }
			.map {
				String(repeating: "\t", count: indentLevel) + $0
			}.joined(separator: "\n")
	}

	func indent(@StringBuilder _ content: () throws -> String) -> String {
		var copy = AnalysisPrinter()
		copy.indentLevel = indentLevel + 1
		return copy.add(content)
	}

	@StringBuilder public func visit(_ expr: AnalyzedCallExpr, _: Void) throws -> String {
		dump(expr)
		indent {
			try expr.calleeAnalyzed.accept(self, ())
			for arg in expr.argsAnalyzed {
				dump(arg)
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedDefExpr, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedErrorSyntax, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedLiteralExpr, _: Void) throws -> String {
		dump(expr, expr.description.debugDescription)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedVarExpr, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedBinaryExpr, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedUnaryExpr, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedIfExpr, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedFuncExpr, _: Void) throws -> String {
		dump(expr, "name: \(expr.name?.lexeme ?? "<none>"), params: \(expr.analyzedParams.paramsAnalyzed.map(\.debugDescription))")
		indent {
			try expr.bodyAnalyzed.accept(self, ())
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedBlockStmt, _: Void) throws -> String {
		dump(expr)
		indent {
			for stmt in expr.stmtsAnalyzed {
				try stmt.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedWhileStmt, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedParamsExpr, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedParam, _: Void) throws -> String {
		dump(expr)
	}

	@StringBuilder public func visit(_ expr: AnalyzedReturnStmt, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedIdentifierExpr, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedMemberExpr, _: Void) throws -> String {
		dump(expr, "name: \(expr.property.debugDescription)")
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedDeclBlock, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedStructExpr, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedVarDecl, _: Void) throws -> String {
		dump(expr, "name: \(expr.name)")
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedLetDecl, _: Void) throws -> String {
		dump(expr, "name: \(expr.name)")
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedImportStmt, _: Void) throws -> String {
		dump(expr, expr.module.debugDescription)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedInitDecl, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedGenericParams, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedTypeExpr, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedExprStmt, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedIfStmt, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	@StringBuilder public func visit(_ expr: AnalyzedStructDecl, _: Void) throws -> String {
		dump(expr)
		indent {
			for child in expr.analyzedChildren {
				try child.accept(self, ())
			}
		}
	}

	// GENERATOR_INSERTION

	public typealias Context = Void
	public typealias Value = String
}
