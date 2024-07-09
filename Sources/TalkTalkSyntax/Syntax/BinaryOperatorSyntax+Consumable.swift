//
//  BinaryOperatorSyntax+Consumable.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
extension BinaryOperatorSyntax: Consumable {
	static func consuming(_ token: Token) -> BinaryOperatorSyntax? {
		let opKind: Kind = switch token.kind {
		case .plus: .plus
		case .minus: .minus
		case .star: .star
		case .slash: .slash
		case .equal: .equal
		case .equalEqual: .equalEqual
		case .bangEqual: .bangEqual
		case .greater: .greater
		case .greaterEqual: .greaterEqual
		case .less: .less
		case .lessEqual: .lessEqual
		case .dot: .dot
		default:
			fatalError("Unreachable")
		}

		return .init(kind: opKind, position: token.start, length: token.length)
	}
}
