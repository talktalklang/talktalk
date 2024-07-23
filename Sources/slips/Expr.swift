public protocol Expr {
}

public extension Expr {
	func cast<T: Expr>(_ type: T.Type) -> T {
		self as! T
	}
}
