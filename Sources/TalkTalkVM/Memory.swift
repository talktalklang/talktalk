//
//  Memory.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public struct Memory {
	public static func malloc<T>(size: Int) -> UnsafeMutableBufferPointer<T> {
		UnsafeMutableBufferPointer<T>.allocate(capacity: size)
	}

	public static func free<T>(_ pointer: UnsafeMutableBufferPointer<T>) {
		pointer.deinitialize()
		pointer.deallocate()
	}
}
