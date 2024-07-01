//
//  VM.swift
//  
//
//  Created by Pat Nakajima on 6/30/24.
//

public struct VM {
	public init() {}

	public func main() {
		var chunk = Chunk()

		chunk.write(.constant, line: 123)
		chunk.write(value: 1.2, line: 123)
		chunk.write(.return, line: 123)
		chunk.disassemble("test chunk")
	}
}
