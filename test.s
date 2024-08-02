	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 14, 0
	.globl	_main                           ; -- Begin function main
	.p2align	2
_main:                                  ; @main
	.cfi_startproc
; %bb.0:                                ; %entry
	sub	sp, sp, #32
	stp	x29, x30, [sp, #16]             ; 16-byte Folded Spill
	.cfi_def_cfa_offset 32
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	mov	x8, #4                          ; =0x4
	mov	w0, w8
	mov	x8, #16                         ; =0x10
                                        ; kill: def $w8 killed $w8 killed $x8
	str	w8, [sp, #4]                    ; 4-byte Folded Spill
	bl	_malloc
	mov	x9, x0
	ldr	w0, [sp, #4]                    ; 4-byte Folded Reload
	str	x9, [sp, #8]                    ; 8-byte Folded Spill
	mov	w8, #123                        ; =0x7b
	str	w8, [x9]
	bl	_malloc
	mov	x1, x0
	ldr	x0, [sp, #8]                    ; 8-byte Folded Reload
	adrp	x8, __fn_x_27@PAGE
	add	x8, x8, __fn_x_27@PAGEOFF
	str	x8, [x1]
	str	x0, [x1, #8]
	mov	x8, x1
	mov	w0, #2                          ; =0x2
	blr	x8
	ldp	x29, x30, [sp, #16]             ; 16-byte Folded Reload
	add	sp, sp, #32
	ret
	.cfi_endproc
                                        ; -- End function
	.globl	__fn_x_27                       ; -- Begin function _fn_x_27
	.p2align	2
__fn_x_27:                              ; @_fn_x_27
	.cfi_startproc
; %bb.0:                                ; %entry
	ldr	w8, [x1, #8]
	add	w0, w8, w0
	ret
	.cfi_endproc
                                        ; -- End function
	.section	__TEXT,__cstring,cstring_literals
l_fmtStr:                               ; @fmtStr
	.asciz	"%d\n"

.subsections_via_symbols
