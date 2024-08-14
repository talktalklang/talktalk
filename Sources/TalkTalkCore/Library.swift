//
//  Library.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/14/24.
//

import Foundation

public struct Library {
	static var libraryURL: URL { Bundle.module.resourceURL! }
	public static var standardLibraryURL: URL { libraryURL.appending(path: "Standard") }
}
