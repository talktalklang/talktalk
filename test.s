	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 14, 0
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:                                ; %entry
	stp	x20, x19, [sp, #-32]!           ; 16-byte Folded Spill
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	.cfi_def_cfa_offset 32
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	mov	w0, #4                          ; =0x4
	bl	_malloc
	mov	w8, #1                          ; =0x1
	mov	x19, x0
	str	w8, [x0]
	mov	w0, #8                          ; =0x8
	bl	_malloc
	mov	x1, x0
	str	x19, [x0]
	mov	w0, #2                          ; =0x2
	bl	__fn_x_25
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	ldp	x20, x19, [sp], #32             ; 16-byte Folded Reload
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	__fn_x_25                       ; -- Begin function _fn_x_25
	.p2align	2
__fn_x_25:                              ; @_fn_x_25
	.cfi_startproc
; %bb.0:                                ; %entry
	ldr	x8, [x1]
	ldr	w8, [x8]
	add	w0, w8, w0
	ret
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_fmtStr:                               ; @fmtStr
	.asciz	"%d\n"

.subsections_via_symbols
