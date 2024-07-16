//
//  CompilerVisitor.swift
//  
//
//  Created by Pat Nakajima on 7/15/24.
//
import TalkTalkSyntax
import TalkTalkTyper
import CLLVM

class Module {

}

struct CompilerVisitor: ASTVisitor {
	var bindings: Bindings

	mutating func visit(_ node: ProgramSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: FunctionDeclSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: VarDeclSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: ClassDeclSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: InitDeclSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: PropertyDeclSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: ExprStmtSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: BlockStmtSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: IfStmtSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: StmtSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: WhileStmtSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: ReturnStmtSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: GroupExpr, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: CallExprSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: UnaryExprSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: BinaryExprSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: IdentifierSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: IntLiteralSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: StringLiteralSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: VariableExprSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: AssignmentExpr, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: LiteralExprSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: PropertyAccessExpr, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: ArrayLiteralSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: IfExprSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: UnaryOperator, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: BinaryOperatorSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: ArgumentListSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: ParameterListSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: ErrorSyntax, context module: Module) -> Module {
		Module()
	}
	
	mutating func visit(_ node: TypeDeclSyntax, context module: Module) -> Module {
		Module()
	}
}
