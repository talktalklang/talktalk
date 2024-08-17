//
//  DynamicArray.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public struct DynamicArray<Element> {
	private var storage: ContiguousArray<Element>
	var capacity: Int

	public init(capacity: Int) {
		self.storage = ContiguousArray<Element>()
		storage.reserveCapacity(capacity)
		self.capacity = capacity
	}

	public subscript(_ index: any FixedWidthInteger) -> Element {
		get {
			storage[Int(index)]
		}

		set {
			storage[Int(index)] = newValue
		}
	}
}

extension DynamicArray: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: Element...) {
		self.storage = ContiguousArray(elements)
		self.capacity = storage.count
	}
}
