import C_LLVM

extension LLVM {
	class Emitter {
		let builder: LLVM.Builder

		init(module: Module) {
			builder = LLVM.Builder(module: module)
		}
	}
}
