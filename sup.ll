declare i32 @printf(i8* noalias nocapture, ...)
declare i8* @malloc(i32)

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

%Closure = type {
	ptr, ; The function pointer
	i32 ; a captured int
}

define i32 @callfn(ptr %closure, i32 %x) {
	%fn = getelementptr inbounds %Closure, ptr %closure, i32 0, i32 0
	%ret = call i32 %fn(i32 %x, ptr %closure)
	ret i32 %ret
}

; The nested function that has a captured i32
define i32 @fn_x(i32 %x, %Closure %env) {
entry:
	call i32 @print_int(i32 222)
	ret i32 0
}

; The parent function that has takes a param that gets captured
; by the nested function it returns
define i32 @fn_y(i32 %y) {
entry:
	
}

define i32 @main() {
entry:
	call i32 @print_int(i32 123)
	ret i32 0
}

define void @print_int(i32 %x) {
entry:
	%format_ptr = getelementptr inbounds [4 x i8], [4 x i8]* @.str, i32 0, i32 0
  call i32 (i8*, ...) @printf(i8* %format_ptr, i32 %x)
  ret void
}
