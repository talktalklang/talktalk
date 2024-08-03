//
//  ObjectType.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/2/24.
//

public enum Object: Equatable, Hashable {
	var stringTag: Byte { 0 }

	public static func ==(lhs: Object, rhs: Object) -> Bool {
		switch (lhs, rhs) {
		case (.string(let lhs), .string(let rhs)):
			return false // TODO: Fix me
		}
	}

	case string(UnsafeMutableBufferPointer<CChar>)

	public var bytes: [Byte] {
		switch self {
		case .string(let pointer):
			[stringTag] + pointer.map { Byte(bitPattern: $0) }
		}
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self)
	}
}
