//
//  OutputBuffer.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/2/24.
//

import Foundation
import TalkTalkBytecode

public enum OutputDestination {
	case stdout, stderr
}

public protocol OutputBuffer {
	mutating func write(_ data: [Byte], to destination: OutputDestination) throws
}

public struct DefaultOutputBuffer: OutputBuffer {
	public init() {}

	public func write(_ data: [Byte], to destination: OutputDestination) throws {
		switch destination {
		case .stdout:
			try FileHandle.standardOutput.write(contentsOf: Data(data))
		case .stderr:
			try FileHandle.standardError.write(contentsOf: Data(data))
		}
	}
}
