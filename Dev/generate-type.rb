typeName = ARGV[0] # protocol name like "FooExpr"
kind = ARGV[1] # expr/stmt/decl

syntaxName = "#{typeName}Syntax"
analyzedName = "Analyzed#{typeName}"

subdir = {
	"expr" => "Exprs",
	"stmt" => "Stmts",
	"decl" => "Decls"
}[kind] || abort("Unknown kind: #{kind}")

conformsTo = {
	"expr" => "Expr",
	"stmt" => "Stmt",
	"decl" => "Decl"
}[kind]

def write(path, contents)
	if File.exists?(path)
		abort("File already exists: #{path}")
	end

	File.open(path, "w+")	do |file|
		file.puts(contents)
	end
end

def insert(path, line, contents)
	lines = File.read(path).lines
	lines.insert(line, contents)
	File.open(path, 'w+') { |file|
		file.puts(lines.join("\n"))
	}
end

syntaxPath = "Sources/TalkTalkSyntax/#{subdir}/#{typeName}.swift"
syntaxFile = <<~SWIFT
// Generated by Dev/generate-type.rb #{Time.now.strftime("%m/%d/%Y %H:%M")}

public protocol #{typeName}: #{conformsTo} {
	// Insert #{typeName} specific fields here
}

public struct #{typeName}Syntax: #{typeName} {
	// Where does this syntax live
	var location: SourceLocation

	// Useful for just traversing the whole tree
	var children: [any Syntax]

	// Let this node be visited by visitors
	func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context: context)
	}
}
SWIFT

analyzedPath = "Sources/TalkTalkAnalysis/#{subdir}/Analyzed#{typeName}.swift"
analyzedFile = <<~SWIFT
// Generated by Dev/generate-type.rb #{Time.now.strftime("%m/%d/%Y %H:%M")}

import TalkTalkSyntax

public struct #{analyzedName}: #{typeName}, Analyzed#{kind} {
	let wrapped: any #{typeName}

	public var typeID: TypeID
	public var analyzedChildren: [any AnalyzedSyntax] { fatalError("TODO") }

	// Delegate these to the wrapped node
	public var expr: any Expr { wrapped.expr }
	public var location: SourceLocation { wrapped.location }
	public var children: [any Syntax] { wrapped.children }

	func accept<V>(_ visitor: V, _ scope: V.Context) throws -> V.Value where V: AnalyzedVisitor {
		try visitor.visit(self, scope)
	}

	func accept<V: Visitor>(_ visitor: V, _ context: V.Context) throws -> V.Value {
		try visitor.visit(self, context: context)
	}
}
SWIFT

visitorRequirement = <<SWIFT
	func visit(_ expr: #{typeName}, _ context: Context) throws -> Value
SWIFT

analysisVisitorRequirement = <<SWIFT
	func visit(_ expr: Analyzed#{typeName}, _ context: Context) throws -> Value
SWIFT

write(syntaxPath, syntaxFile)
puts "wrote #{syntaxPath}"

write(analyzedPath, analyzedFile)
puts "wrote #{analyzedPath}"

insert("Sources/TalkTalkSyntax/Visitor.swift", 12, visitorRequirement)
puts "added visitor requirement to Sources/TalkTalkSyntax/Visitor.swift"

insert("Sources/TalkTalkAnalysis/FileAnalysis/AnalysisVisitor.swift", 12, analysisVisitorRequirement)
puts "added analysis visitor requirement to Sources/TalkTalkAnalysis/FileAnalysis/AnalysisVisitor.swift"

insert "Sources/TalkTalkAnalysis/FileAnalysis/SourceFileAnalyzer.swift", 39, <<SWIFT
	public func visit(_ expr: any {typeName}, _ context: Environment) throws -> any AnalyzedSyntax {
		#warning("TODO")
		fatalError("TODO")
	}

SWIFT
puts "added conformance to SourceFileAnalyzer"

insert "Sources/TalkTalkLSP/Handlers/TextDocumentSemanticTokensFull.swift", 51, <<SWIFT
	func visit(_ expr: any #{typeName}, _ context: Context) throws -> [RawSemanticToken] {
		#warning("TODO")
		fatalError("TODO")
	}

SWIFT
puts "added conformance to SemanticTokensFull visitor"

insert "Sources/TalkTalkSyntax/Visitors/Formatter.swift", 24, <<SWIFT
	public func visit(_ expr: any #{typeName}, _ context: Context) throws -> String {
		#warning("Generated by Dev/generate-type.rb")
		fatalError("TODO")
	}

SWIFT
puts "added conformance to Formatter visitor"

insert "Sources/TalkTalkSyntax/Visitors/ASTPrinter.swift", 77, <<SWIFT
	@StringBuilder public func visit(_ expr: any #{typeName}, _ context: Context) throws -> String {
		dump(expr)
	}

SWIFT
puts "added conformance to ASTPrinter"

insert "Sources/TalkTalk/Interpreter.swift", 46, <<SWIFT
	public func visit(_ expr: Analyzed#{typeName}, _ context: Scope) throws -> Value {
		#warning("Generated by Dev/generate-type.rb")
		fatalError("TODO")
	}

SWIFT

insert "Sources/TalkTalkCompiler/ChunkCompiler.swift", 53, <<SWIFT
	public func visit(_ expr: Analyzed#{typeName}, _ context: Chunk) throws {
		#warning("Generated by Dev/generate-type.rb")
		fatalError("TODO")
	}
SWIFT
