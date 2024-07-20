//
//  CaptureEnvironment.swift
//
//
//  Created by Pat Nakajima on 7/19/24.
//

public struct Capture {
	public var value: TypedValue
}

public class CaptureEnvironment {
	public var parent: CaptureEnvironment?
	public var captures: [String: Capture] = [:]

	init(parent: CaptureEnvironment? = nil) {
		self.parent = parent
	}

	func capture(value: TypedValue, as name: String) {
		captures[name] = Capture(value: value)
	}
}
