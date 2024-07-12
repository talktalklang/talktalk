//
//  UnaryOperator+Consumable.swift
//
//
//  Created by Pat Nakajima on 7/8/24.
//
extension UnaryOperator: Consumable {
	static func consuming(_ token: Token) -> UnaryOperator? {
		let kind: UnaryOperator.Kind? = switch token.kind {
		case .minus: .minus
		case .bang: .bang
		default:
			nil
		}

		guard let kind else {
			return nil
		}

		return .init(start: token, end: token, kind: kind)
	}
}
