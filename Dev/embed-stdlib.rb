entries = []
Dir["Library/Standard/*"].each do |f|
	entries << <<~SWIFT
	"#{File.basename(f)}": """
	#{File.read(f)}
	""",
	SWIFT
end

puts <<~SWIFT
public enum EmbeddedStandardLibrary {
	static var files: [String: String] {
		[
			#{entries.join("\n")}
		]
	}
}
SWIFT
