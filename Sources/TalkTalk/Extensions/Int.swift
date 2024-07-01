//
//  Int.swift
//  
//
//  Created by Pat Nakajima on 7/1/24.
//

extension Int {
	var placeholder: String {
		String(repeating: " ", count: "\(self)".count - 1) + "|"
	}
}
