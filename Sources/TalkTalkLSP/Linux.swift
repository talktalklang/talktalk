#if false && os(Linux)
	import Foundation

	public extension URL {
		static var homeDirectory: URL {
			let home = ProcessInfo.processInfo.environment["HOME"]!
			return URL(fileURLWithPath: home)
		}

		func appending(path: String) -> URL {
			appendingPathComponent(path)
		}
	}
#endif
