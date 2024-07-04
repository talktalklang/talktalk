//
//  Keywords.swift
//
//
//  Created by Pat Nakajima on 7/1/24.
//
struct KeywordTrie: @unchecked Sendable {
	struct Node: @unchecked Sendable {
		var keyword: Token.Kind?
		var children: [Character: Node]

		init(keyword: Token.Kind? = nil, children: [Character: Node]) {
			self.keyword = keyword
			self.children = children
		}

		func lookup(_ char: Character) -> Node {
			children[char] ?? .init(children: [:])
		}

		var description: String {
			"Node(children: \(children.keys), keyword: \(keyword as Any)"
		}
	}

	static let trie = {
		var trie = KeywordTrie()
		for keyword in list {
			trie.insert(keyword)
		}
		return trie
	}()

	var root: Node = .init(children: [:])

	func insert(_ keyword: Token.Kind) {
		var currentNode = root

		for char in Array("\(keyword)") {
			if let node = currentNode.children[char] {
				currentNode = node
			} else {
				let newNode = Node(children: [:])
				currentNode.children[char] = newNode
				currentNode = newNode
			}
		}

		currentNode.keyword = keyword
	}
}

extension KeywordTrie {
	static let list: [Token.Kind] = [
		.class,
		.else,
		.false,
		.func,
		.initializer,
		.for,
		.if,
		.nil,
		.or,
		.print,
		.return,
		.super,
		.self,
		.true,
		.var,
		.while,
	]
}
