//
//  String.swift
//
//
//  Created by Pat Nakajima on 7/14/24.
//
extension String {
	func position(line: Int, column: Int) -> Int {
		var position = 0

		for (i, lineText) in components(separatedBy: .newlines).enumerated() {
			if i + 1 == line {
				return position + (column - 1)
			}

			position += lineText.count
			position += 1 // for the newline
		}

		return position
	}

	func inlineOffset(for position: Int, line: Int) -> Int {
		assert(line > 0, "Lines start at index 1")

		var offset = 0
		for (i, lineText) in components(separatedBy: .newlines).enumerated() {
			if i + 1 == line {
				return position - offset + 1
			}

			offset += lineText.count + 1 // +1 for the newline
		}

		return 0
	}
}
