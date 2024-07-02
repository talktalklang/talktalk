//
//  String.swift
//  
//
//  Created by Pat Nakajima on 7/1/24.
//
extension String {
	func index(at offset: Int) -> String.Index {
		index(startIndex, offsetBy: offset)
	}

	subscript(_ offset: Int) -> Character {
		self[index(startIndex, offsetBy: offset)]
	}

	subscript(_ range: Range<Int>) -> Substring {
		self[index(at: range.lowerBound)..<index(at: range.upperBound)]
	}
}
