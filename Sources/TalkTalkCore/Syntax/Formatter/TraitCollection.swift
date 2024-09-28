//
//  TraitCollection.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/13/24.
//

class TraitCollection<T: Hashable> {
	private var traits: Set<T> = .init()

	init(traits: Set<T> = .init()) {
		self.traits = traits
	}

	func copy() -> TraitCollection<T> {
		TraitCollection(traits: traits)
	}

	func add(_ trait: T) {
		traits.insert(trait)
	}

	func has(_ trait: T) -> Bool {
		traits.contains(trait)
	}
}
