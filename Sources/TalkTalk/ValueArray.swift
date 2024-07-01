//
//  ValueArray.swift
//  
//
//  Created by Pat Nakajima on 6/30/24.
//

class ValueArray {
	typealias T = Value

	var count = 0
	var capacity = 0
	var storage = UnsafeMutableRawPointer.allocate(byteCount: 0, alignment: 0)
}
