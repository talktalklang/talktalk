//
//  Log.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/6/24.
//

import Foundation

public enum Log {
	public static func info(_ message: String) {
		log("[info] \(message, color: .cyan)")
	}

	public static func error(_ message: String) {
		log("[error] \(message, color: .red)")
	}

	private static func log(_ message: String) {
		guard FileManager.default.fileExists(atPath: URL.homeDirectory.appending(path: "apps/talktalk/lsp.log").path) else {
			return
		}

		let logfile = URL.homeDirectory.appending(path: "apps/talktalk/lsp.log")
		try? append(data: Data(message.utf8), to: logfile)
		try? append(data: Data("\n".utf8), to: logfile)
	}

	static func append(data: Data, to fileURL: URL) throws {
		if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
			defer {
				fileHandle.closeFile()
			}
			fileHandle.seekToEndOfFile()
			fileHandle.write(data)
		} else {
			try data.write(to: fileURL, options: .atomic)
		}
	}
}

enum ASCIIColor: String {
		case black = "\u{001B}[0;30m"
		case red = "\u{001B}[0;31m"
		case green = "\u{001B}[0;32m"
		case yellow = "\u{001B}[0;33m"
		case blue = "\u{001B}[0;34m"
		case magenta = "\u{001B}[0;35m"
		case cyan = "\u{001B}[0;36m"
		case white = "\u{001B}[0;37m"
		case `default` = "\u{001B}[0;0m"
}

extension DefaultStringInterpolation {
		mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T, color: ASCIIColor) {
				appendInterpolation("\(color.rawValue)\(value)\(ASCIIColor.default.rawValue)")
		}
}
