//
//  OutputCapture.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 8/9/24.
//

import Foundation

public struct OutputCapture: Sendable {
	public struct Result: Sendable {
		public let stdout: String
		public let stderr: String
	}

	static let instance = OutputCapture()
	private init() {}

	public static func run(block: () throws -> Void) rethrows -> Result {
		try instance.run(block)
	}

	@MainActor public static func run(
		block: @Sendable () async throws -> Void
	) async rethrows -> Result {
		try await instance.run(block)
	}

	func run(_ block: () async throws -> Void) async rethrows -> Result {
		// Create pipes for capturing stdout and stderr
		var stdoutPipe = [Int32](repeating: 0, count: 2)
		var stderrPipe = [Int32](repeating: 0, count: 2)
		pipe(&stdoutPipe)
		pipe(&stderrPipe)

		// Save original stdout and stderr
		let originalStdout = dup(STDOUT_FILENO)
		let originalStderr = dup(STDERR_FILENO)

		// Redirect stdout and stderr to the pipes
		dup2(stdoutPipe[1], STDOUT_FILENO)
		dup2(stderrPipe[1], STDERR_FILENO)
		close(stdoutPipe[1])
		close(stderrPipe[1])

		// Execute the block and capture the output
		do {
			try await block()
		} catch {
			// Restore original stdout and stderr
			dup2(originalStdout, STDOUT_FILENO)
			dup2(originalStderr, STDERR_FILENO)
			close(originalStdout)
			close(originalStderr)

			throw error
		}

		// Restore original stdout and stderr
		dup2(originalStdout, STDOUT_FILENO)
		dup2(originalStderr, STDERR_FILENO)
		close(originalStdout)
		close(originalStderr)

		// Read captured output
		let stdoutData = readData(from: stdoutPipe[0])
		let stderrData = readData(from: stderrPipe[0])

		// Convert data to strings
		let stdoutOutput = String(data: stdoutData, encoding: .utf8) ?? ""
		let stderrOutput = String(data: stderrData, encoding: .utf8) ?? ""

		return Result(stdout: stdoutOutput, stderr: stderrOutput)
	}

	func run(_ block: () throws -> Void) rethrows -> Result {
		// Create pipes for capturing stdout and stderr
		var stdoutPipe = [Int32](repeating: 0, count: 2)
		var stderrPipe = [Int32](repeating: 0, count: 2)
		pipe(&stdoutPipe)
		pipe(&stderrPipe)

		// Save original stdout and stderr
		let originalStdout = dup(STDOUT_FILENO)
		let originalStderr = dup(STDERR_FILENO)

		// Redirect stdout and stderr to the pipes
		dup2(stdoutPipe[1], STDOUT_FILENO)
		dup2(stderrPipe[1], STDERR_FILENO)
		close(stdoutPipe[1])
		close(stderrPipe[1])

		// Execute the block and capture the output
		do {
			try block()
		} catch {
			// Restore original stdout and stderr
			dup2(originalStdout, STDOUT_FILENO)
			dup2(originalStderr, STDERR_FILENO)
			close(originalStdout)
			close(originalStderr)

			throw error
		}

		// Restore original stdout and stderr
		dup2(originalStdout, STDOUT_FILENO)
		dup2(originalStderr, STDERR_FILENO)
		close(originalStdout)
		close(originalStderr)

		// Read captured output
		let stdoutData = readData(from: stdoutPipe[0])
		let stderrData = readData(from: stderrPipe[0])

		// Convert data to strings
		let stdoutOutput = String(data: stdoutData, encoding: .utf8) ?? ""
		let stderrOutput = String(data: stderrData, encoding: .utf8) ?? ""

		return Result(stdout: stdoutOutput, stderr: stderrOutput)
	}

	private func readData(from fd: Int32) -> Data {
		var data = Data()
		let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
		defer { buffer.deallocate() }

		while true {
			let count = read(fd, buffer, 1024)
			if count <= 0 {
				break
			}
			data.append(buffer, count: count)
		}

		return data
	}

}
