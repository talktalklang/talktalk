//
//  BinaryOperation.swift
//  LLVM
//
//  Created by Pat Nakajima on 7/25/24.
//

import C_LLVM

public extension LLVM {
	enum BinaryOperator {
		case add, equals, notEquals, less, lessEqual, greater, greaterEqual, minus, star, slash
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
			case .minus:
				let ref = LLVMBuildSub(builder.builder, lhs.ref, rhs.ref, "subtmp")!
				return EmittedIntValue(type: .i32, ref: ref)
			case .star:
				let ref = LLVMBuildMul(builder.builder, lhs.ref, rhs.ref, "mlttmp")!
				return EmittedIntValue(type: .i32, ref: ref)
			case .slash:
				let ref = LLVMBuildSDiv(builder.builder, lhs.ref, rhs.ref, "divtmp")!
				return EmittedIntValue(type: .i32, ref: ref)
			case .equals:
				let op = LLVMIntEQ
				let ref = LLVMBuildICmp(builder.builder, op, lhs.ref, rhs.ref, "eqltmp")!
				return EmittedIntValue(type: .i1, ref: ref)
			case .notEquals:
				let op = LLVMIntNE
				let ref = LLVMBuildICmp(builder.builder, op, lhs.ref, rhs.ref, "eqltmp")!
				return EmittedIntValue(type: .i1, ref: ref)
			case .less:
				let op = LLVMIntSLT
				let ref = LLVMBuildICmp(builder.builder, op, lhs.ref, rhs.ref, "eqltmp")!
				return EmittedIntValue(type: .i1, ref: ref)
			case .lessEqual:
				let op = LLVMIntSLE
				let ref = LLVMBuildICmp(builder.builder, op, lhs.ref, rhs.ref, "eqltmp")!
				return EmittedIntValue(type: .i1, ref: ref)
			case .greater:
				let op = LLVMIntSGT
				let ref = LLVMBuildICmp(builder.builder, op, lhs.ref, rhs.ref, "eqltmp")!
				return EmittedIntValue(type: .i1, ref: ref)
			case .greaterEqual:
				let op = LLVMIntSGE
				let ref = LLVMBuildICmp(builder.builder, op, lhs.ref, rhs.ref, "eqltmp")!
				return EmittedIntValue(type: .i1, ref: ref)
			}
		}
	}
}
