//
//  BinaryOperation.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM {
	enum BinaryOperator {
		case add, equals, notEquals
	}

	struct BinaryOperation<V: EmittedValue>: IRValue {
		public typealias T = V.T

		public let lhs: V
		public let rhs: V
		public let op: BinaryOperator

		public var type: V.T

		public init(op: BinaryOperator, lhs: V, rhs: V) {
			self.op = op
			self.lhs = lhs
			self.rhs = rhs
			self.type = lhs.type
		}

		public func emit(in builder: Builder) -> any EmittedValue {
			switch lhs {
			case is EmittedIntValue:
				return intOperation(op, lhs: lhs, rhs: rhs, in: builder)
			default:
				fatalError()
			}
		}

		func intOperation(_ op: BinaryOperator, lhs: V, rhs: V, in builder: Builder) -> EmittedIntValue {
			switch op {
			case .add:
				let ref = LLVMBuildAdd(builder.builder, lhs.ref, rhs.ref, "addtmp")!
				return EmittedIntValue(type: .i32, ref: ref)
			case .equals:
				let op = LLVMIntEQ
				let ref = LLVMBuildICmp(builder.builder, op, lhs.ref, rhs.ref, "eqltmp")!
				return EmittedIntValue(type: .i1, ref: ref)
			case .notEquals:
				let op = LLVMIntNE
				let ref = LLVMBuildICmp(builder.builder, op, lhs.ref, rhs.ref, "eqltmp")!
				return EmittedIntValue(type: .i1, ref: ref)
			}
		}
	}
}
