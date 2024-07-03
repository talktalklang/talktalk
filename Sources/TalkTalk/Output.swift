//
//  Output.swift
//  
//
//  Created by Pat Nakajima on 7/2/24.
//

public protocol OutputCollector: AnyObject {
	func print(_ output: String, terminator: String)
	func debug(_ output: String, terminator: String)
}

public final class StdoutOutput: OutputCollector {
	public func print(_ output: String, terminator: String) {
		Swift.print(output, terminator: terminator)
	}

	public func debug(_ output: String, terminator: String) {
		Swift.print(output, terminator: terminator)
	}

	public init() {}
}

public extension OutputCollector {
	func print() {
		self.print("")
	}

	func debug() {
		self.debug("", terminator: "\n")
	}

	func debug(_ output: String) {
		self.debug(output, terminator: "\n")
	}

	func print(_ output: String) {
		self.print(output, terminator: "\n")
	}

	func printf(_ string: String, _ args: CVarArg...) {
		self.print(String(format: string, args), terminator: "")
	}

	func print(format string: String, _ args: CVarArg...) {
		self.print(String(format: string, args))
	}
}
