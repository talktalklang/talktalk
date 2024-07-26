; ModuleID = 'main'
source_filename = "main"

define i32 @main() {
entry:
  %addtwo = alloca ptr, align 8
  store ptr @fn_x, ptr %addtwo, align 8
  %fn_x_call = load ptr, ptr %addtwo, align 8
  %fn_x = call i32 %fn_x_call(i32 2)
  ret i32 %fn_x
}

define i32 @fn_x(i32 %0) {
entry:
  %tmp = add i32 %0, 2
  ret i32 %tmp
}
