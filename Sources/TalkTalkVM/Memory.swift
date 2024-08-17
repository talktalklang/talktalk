//
//  Memory.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public enum Memory {
	public static func malloc<T>(size: Int) -> UnsafeMutableBufferPointer<T> {
		UnsafeMutableBufferPointer<T>.allocate(capacity: size)
	}

	public static func free(_ pointer: UnsafeMutableBufferPointer<some Any>) {
		pointer.deinitialize()
		pointer.deallocate()
	}
}
