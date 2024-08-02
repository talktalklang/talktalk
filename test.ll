; ModuleID = 'main'
source_filename = "main"

%_fn_x_25.closure.ptr = type { ptr }

@fmtStr = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

define i32 @main() {
entry:
  %i = tail call ptr @malloc(i32 ptrtoint (ptr getelementptr (i32, ptr null, i32 1) to i32))
  store i32 1, ptr %i, align 4
  %_fn_x_25.closure.ptr = tail call ptr @malloc(i32 ptrtoint (ptr getelementptr (%_fn_x_25.closure.ptr, ptr null, i32 1) to i32))
  %capture.i.gep = getelementptr inbounds %_fn_x_25.closure.ptr, ptr %_fn_x_25.closure.ptr, i32 0, i32 0
  store ptr %i, ptr %capture.i.gep, align 8
  %_fn_x_25.call = call i32 @_fn_x_25(i32 2, ptr %_fn_x_25.closure.ptr)
  ret i32 %_fn_x_25.call
}

declare i32 @printf(ptr %0, ...)

declare noalias ptr @malloc(i32 %0)

define i32 @_fn_x_25(i32 %x, ptr %0) {
entry:
  %capture.0.gep = getelementptr inbounds %_fn_x_25.closure.ptr, ptr %0, i32 0, i32 0
  %capture.0.heap = load ptr, ptr %capture.0.gep, align 8
  %capture.0.load = load i32, ptr %capture.0.heap, align 4
  %addtmp = add i32 %capture.0.load, %x
  ret i32 %addtmp
}
