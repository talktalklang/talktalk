import TalkTalkSyntax
import TalkTalkTyper
import C_LLVM

public struct CompilerABTVisitor: ABTVisitor {
	let emitter: LLVM.Emitter

	init(module: LLVM.Module) {
		self.emitter = LLVM.Emitter(module: module)
	}

	public func visit(_ node: Program) -> any LLVM.IR {
		returnLast(in: node.declarations)
	}

	public func visit(_ node: Block) -> any LLVM.IR {
		returnLast(in: node.children)
	}

	public func visit(_ node: Literal) -> any LLVM.IR {
		let res = node.value.get()

		return res
	}

	public func visit(_ node: Function) -> any LLVM.IR {
		.i1()
	}

	public func visit(_ node: VoidNode) -> any LLVM.IR {
		.i1()
	}

	public func visit(_ node: IfExpression) -> any LLVM.IR {
		.i1()
	}

	public func visit(_ node: OperatorNode) -> any LLVM.IR {
		switch node.syntax.cast(BinaryOperatorSyntax.self).kind {
		case .plus:
			LLVMAdd
		default:
			.i1()
		}
	}

	public func visit(_ node: TypeDeclaration) -> any LLVM.IR {
		.i1()
	}

	public func visit(_ node: VarLetDeclaration) -> any LLVM.IR {
		.i1()
	}

	public func visit(_ node: BinaryOpExpression) -> any LLVM.IR {
		let lhs = node.lhs.accept(self)
		let rhs = node.rhs.accept(self)

		let op = visit(node.op)

		return emitter.emit(
			binaryOp: op.asLLVM(),
			lhs: lhs.asLLVM(),
			rhs: rhs.asLLVM()
		)
	}

	public func visit(_ node: TODONode) -> any LLVM.IR {
		.i1()
	}

	public func visit(_ node: UnknownSemanticNode) -> any LLVM.IR {
		.i1()
	}

	// MARK: Helpers

	private func returnLast(in nodes: [any SemanticNode]) -> any LLVM.IR {
		var lastReturn: (any LLVM.IR)?
		for node in nodes {
			lastReturn = node.accept(self)
		}
		return lastReturn!
	}
}
