talk.wasm: Sources/TalkTalkCore/embedded-stdlib.swift
	/Library/Developer/Toolchains/swift-wasm-DEVELOPMENT-SNAPSHOT-2024-09-20-a.xctoolchain/usr/bin/swift build \
		--triple wasm32-unknown-wasi \
		--product talk \
		--static-swift-stdlib \
		--configuration release \
		--scratch-path .build/wasm \
		-Xswiftc -Osize
	cp .build/wasm/wasm32-unknown-wasi/release/talk.wasm .
	wasm-strip talk.wasm
	wasm-opt -o talk.wasm --enable-bulk-memory -Oz talk.wasm

Sources/TalkTalkCore/embedded-stdlib.swift:
	ruby Dev/embed-stdlib.rb > Sources/TalkTalkCore/embedded-stdlib.swift

debug:
	swift build --product talk --configuration debug

.PHONY: clean
clean:
	rm talk.wasm ||	true
	rm -rf .build
	rm Sources/TalkTalkCore/embedded-stdlib.swift || true
